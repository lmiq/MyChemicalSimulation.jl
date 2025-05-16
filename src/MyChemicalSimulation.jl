module MyChemicalSimulation

using GLMakie
using StaticArrays
using CellListMap
using LinearAlgebra: norm
using Statistics: mean

export main
export simulation_state

@kwdef mutable struct ParticleState
	f::SVector{2,Float32} = zero(SVector{2,Float32}) # force
	color::Symbol = :blue
	type::Symbol = :circle
end

@kwdef mutable struct SimulationData
    N0::Vector{Int} = [500, 500, 0, 0]
    N::Int = sum(N0)
    kvec::Vector{Float64} = [0.5, 0.5]
    temperature::Float32 = 298.15
    cutoff::Float32 = 3.0f0
    box_size::Float32 = 2 * sqrt(N) * cutoff
    dt::Float32 = 1.0f0
    nsteps::Int = 100
    colors::Vector{Symbol} = [:blue, :red, :green, :orange]
    initial_positions = box_size * rand(Point2f, N)
    initial_states::Vector{ParticleState} = vcat(
    	[ParticleState(;color=colors[1], type=:circle) for _ in 1:N0[1]],
    	[ParticleState(;color=colors[2], type=:star5) for _ in 1:N0[2]],
    	[ParticleState(;color=colors[3], type=:circle) for _ in 1:N0[3]],
    	[ParticleState(;color=colors[4], type=:star5) for _ in 1:N0[4]],
    )
end

include("./simulation.jl")

function observables()
    obs = (
        positions = Observable(SVector{2,Float32}[]),
        markercolor = Observable(Symbol[]),
        step_title = Observable(""),
        nmols_title = Observable(""),
        q_title = Observable(""),
        nmols_time = [ Observable(Int[]) for _ in 1:4 ], # vector of observables
        nmols_current = Observable(Int[]),
    )
    return obs
end

@kwdef mutable struct SimulationState
    sim = SimulationData()
    obs = observables()
    fig = Figure(size=(1800, 1000))
    stop::Bool = false
end
simulation_state = SimulationState()



function main()
    global simulation_state

    (; obs, fig) = simulation_state

    # Figure layout
    Axis(fig[1:2,1], title=obs.step_title)
    Axis(fig[1,2])
    Axis(fig[2,2], title=obs.nmols_title)
    ax = Axis(fig[3,1:2])
    hidedecorations!(ax)

    # Setup simulation and plots
    setup!()

    # 
    # Buttons
    #
    fig[3,1:2] = buttongrid = GridLayout(tellwidth=false)
    buttons = buttongrid[1, 1:3] = [ 
        Button(fig, label="Setup"), 
        Button(fig, label="Run"), 
        Button(fig, label="Stop"),
    ]
    on(buttons[1].clicks) do _
        setup!()
        return nothing
    end
    on(buttons[2].clicks) do _
        simulate!()
        return nothing
    end
    on(buttons[3].clicks) do _ 
        simulation_state.stop = true
        return nothing
    end
    colsize!(fig.layout, 1, Relative(2/3))
    rowsize!(fig.layout, 3, Relative(1/10))

    return fig
end

function setup!()
    global simulation_state
    (; sim, obs, fig) = simulation_state
    
    #
    # GUI properties
    #
    obs.positions[] = sim.initial_positions
    obs.markercolor[] = [x.color for x in sim.initial_states]
    obs.step_title[] = "k₁ = $(sim.kvec[1]), k₂ = $(sim.kvec[2]) - Step = 0"

    # Number of molecules of each time, over time and current
    for ic in eachindex(sim.colors)
        obs.nmols_time[ic][] = vcat([count(x -> x.color == sim.colors[ic], sim.initial_states)],[0 for _ in 2:sim.nsteps])
    end
    obs.nmols_current[] = [ first(nmols_time[]) for nmols_time in obs.nmols_time ]

    # Reaction quotient string
    q = obs.nmols_current[][3]*obs.nmols_current[][4]/(obs.nmols_current[][1]*obs.nmols_current[][2])
    obs.q_title[] = "Q = $(round(q, digits=5))"
    obs.nmols_title[]="Número de Moléculas - N = [$(join(obs.nmols_current[], ", "))]"

    #
    # Scatter plot of the positions
    #
    ax = content(fig[1:2,1])
    brd = round(Int, sim.box_size/50)
    ax.limits=(-brd, sim.box_size+brd, -brd, sim.box_size+brd)
    scatter!(fig[1:2,1],
    	obs.positions,
    	markersize=15,
    	color=obs.markercolor,
    	marker=[x.type for x in sim.initial_states],
    )

    #
    # Bar plot of the number of particules of each type
    #
    yscale = sum(x -> x.color != :transparent, sim.initial_states)
    barplot!(fig[1,2], 
        [1,2,3,4],
        obs.nmols_current,
        color=sim.colors,
    )
    ax = content(fig[1,2])
    ax.title="Histograma - N₀ = $(sim.N0)"
    ax.xlabel="Tipo"
    ax.ylabel="Número"
    ax.limits=(0, 5, 0, yscale)

    text!(fig[1,2], obs.q_title, position = (4.0, 0.95*yscale))

    #
    # Quantities over time
    #
    ax = content(fig[2,2])
    ax.xlabel="Tempo"
    ax.ylabel="Número"
    ax.limits=(0, sim.nsteps, 0, yscale)
    for ic in eachindex(sim.colors)
        scatter!(fig[2,2], 
            1:sim.nsteps, 
            obs.nmols_time[ic],
            color=sim.colors[ic],
            markersize=5,
        )
    end

    return nothing
end

function simulate!()
    global simulation_state
    (; sim, obs) = simulation_state
    sys = ParticleSystem(
    	xpositions=copy(sim.initial_positions),
    	unitcell=Float32[sim.box_size, sim.box_size],
    	cutoff=sim.cutoff,
    	output=deepcopy(sim.initial_states),
    	output_name=:states,
    	parallel=false,
    )
    simulation_state.stop = false
    t0 = sim.temperature - 208.15 # for 298.15K, becomes 90, which is reasonable here
    velocities = randn(SVector{2,Float32}, sim.N)
    velocities, _ = thermalize!(velocities, t0)
    for istep in 1:sim.nsteps
    	current_states = map_pairwise!(
            (x,y,i,j,d2,out) -> update_particles!(x,y,i,j,d2,out,sys,sim.kvec,sim.colors), 
            sys
        )
        thermalize!(velocities, t0)
    	for i in eachindex(sys.xpositions, velocities, current_states)
    	 	p = sys.xpositions[i]
    		v = velocities[i]
        	p = p + v * sim.dt + current_states[i].f * sim.dt^2
    		v = v + current_states[i].f * sim.dt
    		p, v = wall_bump(p, v, sim.box_size)
    		sys.xpositions[i] = p
    		velocities[i] = v
    	end
    	obs.positions[] = sys.xpositions
    	obs.markercolor[] = [x.color for x in current_states]
        obs.step_title[] = "k₁ = $(sim.kvec[1]), k₂ = $(sim.kvec[2]) - Step = $istep"
        for ic in eachindex(sim.colors)
            obs.nmols_time[ic][][istep] = count(x -> x.color == sim.colors[ic], current_states)
            obs.nmols_time[ic][] = obs.nmols_time[ic][]
        end
        obs.nmols_current[] = [ nmols_time[][istep] for nmols_time in obs.nmols_time ]
        obs.nmols_title[]="Número de Moléculas - N = [$(join(obs.nmols_current[], ", "))]"
        q = obs.nmols_current[][3]*obs.nmols_current[][4]/(obs.nmols_current[][1]*obs.nmols_current[][2])
        obs.q_title[] = "Q = $(round(q, digits=5))"
    	sleep(1/50)
        simulation_state.stop && break
    end
    return nothing
end

end
