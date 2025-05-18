module MyChemicalSimulation

using GLMakie
using StaticArrays
using CellListMap
using LinearAlgebra: norm
using Statistics: mean

export main

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
    time::Float64 = 1.0
    step::Int = 0
    nsteps::Int = round(Int, 60 * 30 * time)
    colors::Vector{Symbol} = [:blue, :red, :green, :orange]
    positions = box_size * rand(Point2f, N)
    initial_states::Vector{ParticleState} = vcat(
    	[ParticleState(;color=colors[1], type=:circle) for _ in 1:N0[1]],
    	[ParticleState(;color=colors[2], type=:star5) for _ in 1:N0[2]],
    	[ParticleState(;color=colors[3], type=:circle) for _ in 1:N0[3]],
    	[ParticleState(;color=colors[4], type=:star5) for _ in 1:N0[4]],
    )
    current_state::Vector{ParticleState} = deepcopy(initial_states)
    N_over_time::Vector{Vector{Int}} = [
        [i == 1 ? N0[1] : 0 for i in 1:nsteps],
        [i == 1 ? N0[2] : 0 for i in 1:nsteps],
        [i == 1 ? N0[3] : 0 for i in 1:nsteps],
        [i == 1 ? N0[4] : 0 for i in 1:nsteps],
    ]
    stop::Bool = false
end
SimulationData(sim::SimulationData) =
    SimulationData((field = getfield(sim, field) for field in fieldnames(SimulationData))...)

include("./simulation.jl")

function get_N(sim)
    N1 = count(p -> p.color == sim.colors[1], sim.current_state)
    N2 = count(p -> p.color == sim.colors[2], sim.current_state)
    N3 = count(p -> p.color == sim.colors[3], sim.current_state)
    N4 = count(p -> p.color == sim.colors[4], sim.current_state)
    return (N1, N2, N3, N4)
end

function compute_Q(sim)
    N1, N2, N3, N4 = get_N(sim)
    return (N3*N4)/(N1*N2)
end

function up!(obs::Observable, field::Symbol, value)
    sim = obs[]
    setfield!(sim, field, value)
    obs[] = SimulationData(sim)
    return nothing
end

yscale(sim) = sum(x -> x.color != :transparent, sim.initial_states)

function main()
    sim = SimulationData()
    obs = Observable(sim)

    #
    # Setup
    #
    fig = Figure(size=(1200, 800))
    fig[1:2,1] = setup_grid = GridLayout(tellwidth=false)

    setup_grid[1:6, 1] = [
        Label(fig, "Temperatura:", halign=:right),
        Label(fig, "Azul:", halign=:right),
        Label(fig, "Vermelho:", halign=:right),
        Label(fig, "Laranja:", halign=:right),
        Label(fig, "Verde:", halign=:right),
        Label(fig, "tempo:", halign=:right),
    ]
    setup_grid[1:6, 3] = [
        Label(fig, "K", halign=:left),
        Label(fig, "", halign=:left),
        Label(fig, "", halign=:left),
        Label(fig, "", halign=:left),
        Label(fig, "", halign=:left),
        Label(fig, "min", halign=:left),
    ]
    tb = setup_grid[1:6, 2] = [
        Textbox(fig, placeholder=@lift(string(round($(obs).temperature; digits=2))), validator=Float64, width=100, halign=:right),
        Textbox(fig, placeholder=@lift(string($(obs).N0[1])), validator=Int, width=100),
        Textbox(fig, placeholder=@lift(string($(obs).N0[2])), validator=Int, width=100),
        Textbox(fig, placeholder=@lift(string($(obs).N0[3])), validator=Int, width=100),
        Textbox(fig, placeholder=@lift(string($(obs).N0[4])), validator=Int, width=100),
        Textbox(fig, placeholder=@lift(string($(obs).time)), validator=Float64, width=100),
    ]
    on(tb[1].stored_string) do s
        up!(obs, :temperature, parse(Float32, s))
    end
    on(tb[2].stored_string) do s
        up!(obs, :N0, [i == 1 ? parse(Int, s) : obs[].N0[i] for i in eachindex(sim.colors)])
    end
    on(tb[3].stored_string) do s
        up!(obs, :N0, [i == 2 ? parse(Int, s) : obs[].N0[i] for i in eachindex(sim.colors)])
    end
    on(tb[4].stored_string) do s
        up!(obs, :N0, [i == 3 ? parse(Int, s) : obs[].N0[i] for i in eachindex(sim.colors)])
    end
    on(tb[5].stored_string) do s
        up!(obs, :N0, [i == 4 ? parse(Int, s) : obs[].N0[i] for i in eachindex(sim.colors)])
    end
    on(tb[6].stored_string) do s
        up!(obs, :time, parse(Float64, s))
    end

    setup_grid[7,1] = [ Label(fig, "") ]

    sb = setup_grid[8, 1] = [ Button(fig, label="Setup") ] 
    on(sb[1].clicks) do _
        setup!(fig, obs)
    end

    rb = setup_grid[8, 2] = [ Button(fig, label="Run") ] 
    on(rb[1].clicks) do _
        @async simulate!(obs)
    end

    stopb = setup_grid[8, 3] = [ Button(fig, label="Stop") ] 
    on(stopb[1].clicks) do _ 
        up!(obs, :stop, true)
    end

    # Figure layout
    Axis(fig[1:2,2], title=@lift("k₁ = "*string($(obs).kvec[1])*" k₂ = "*string($(obs).kvec[2])*" - Step = "*string($(obs).step)))
    Axis(fig[1,3]; 
        title=@lift("Histograma - N₀ = "*string($(obs).N0)),
        xlabel="Tipo",
        ylabel="Número",
        limits=@lift((0, 5, 0, yscale($obs))),
    )
    text!(fig[1,3], @lift("Q = "*string(round(compute_Q($obs);digits=5))), position=@lift((4.0, 0.95*yscale($obs))))

    Axis(fig[2,3], 
        title=@lift("Número de Moléculas - N = ["*join(get_N($obs), ", ")*"]"),
        xlabel="Tempo",
        ylabel="Número",
        limits=@lift((0, $(obs).time, 0, yscale($obs)))
    )

    # Setup simulation and plots
    setup!(fig, obs)

    colsize!(fig.layout, 1, Relative(2/10))
    colsize!(fig.layout, 2, Relative(5/10))
    colsize!(fig.layout, 3, Relative(3/10))

    return fig
end

function setup!(fig, obs)
    sim = obs[]
    sim = SimulationData(
        N0 = sim.N0,
        temperature = sim.temperature,
        time = sim.time
    )
    obs[] = sim

    #
    # Scatter plot of the positions
    #
    ax = content(fig[1:2,2])
    brd = round(Int, sim.box_size/50)
    ax.limits=(-brd, sim.box_size+brd, -brd, sim.box_size+brd)
    scatter!(fig[1:2,2],
    	@lift($(obs).positions),
    	markersize=15,
    	color=@lift(getfield.($(obs).current_state, :color)),
    	marker=[x.type for x in sim.initial_states],
    )

    #
    # Bar plot of the number of particules of each type
    #
    barplot!(fig[1,3], 
        [1,2,3,4],
        @lift([get_N($obs)...]),
        color=@lift($(obs).colors),
    )

    #
    # Quantities over time
    #
    for ic in eachindex(sim.colors)
        scatter!(fig[2,3], 
            @lift([(i*$(obs).time/$(obs).nsteps, $(obs).N_over_time[ic][i]) for i in 1:$(obs).nsteps]),
            color=@lift($(obs).colors[ic]),
            markersize=5,
        )
    end

    return nothing
end

function simulate!(obs)
    sim = obs[]
    sim.stop = false
    sys = ParticleSystem(
    	xpositions=copy(sim.positions),
    	unitcell=Float32[sim.box_size, sim.box_size],
    	cutoff=sim.cutoff,
    	output=sim.current_state,
    	output_name=:states,
    	parallel=false,
    )
    t0 = 90*sim.temperature/298.15 # for 298.15K, becomes 90, which is reasonable here
    velocities = randn(SVector{2,Float32}, sim.N)
    velocities, _ = thermalize!(velocities, t0)
    for istep in 1:sim.nsteps
    	current_state = map_pairwise!(
            (x,y,i,j,d2,out) -> update_particles!(x,y,i,j,d2,out,sys,sim.kvec,sim.colors), 
            sys
        )
        thermalize!(velocities, t0)
    	for i in eachindex(sys.xpositions, velocities, current_state)
    	 	p = sys.xpositions[i]
    		v = velocities[i]
        	p = p + v * sim.dt + current_state[i].f * sim.dt^2
    		v = v + current_state[i].f * sim.dt
    		p, v = wall_bump(p, v, sim.box_size)
    		sys.xpositions[i] = p
    		velocities[i] = v
    	end
        # Update simulation data object and figures
        sim.step = istep
        sim.positions .= sys.xpositions
        N_current = get_N(sim)
        for ic in eachindex(sim.colors)
            sim.N_over_time[ic][istep] = N_current[ic]
        end
        obs[].stop && break
        obs[] = SimulationData(sim)
    	sleep(1/30)
    end
    return nothing
end

end
