module MyChemicalSimulation

using GLMakie
using StaticArrays
using CellListMap
using LinearAlgebra: norm
using Statistics: mean

export simulate

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
    enthalpy::Float32 = 0.0
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
    N_over_time::Vector{Vector{Int}} = [ [N0[1]], [N0[2]], [N0[3]], [N0[4]] ]
    stop::Bool = true
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
    ihalf = max(1,div(length(sim.N_over_time[1]),2))
    N1 = mean(sim.N_over_time[1][ihalf:end])
    N2 = mean(sim.N_over_time[2][ihalf:end])
    N3 = mean(sim.N_over_time[3][ihalf:end])
    N4 = mean(sim.N_over_time[4][ihalf:end])
    return (N3*N4)/(N1*N2)
end

function up!(obs::Observable, field::Symbol, value)
    sim = obs[]
    setfield!(sim, field, value)
    obs[] = SimulationData(sim)
    return nothing
end

yscale(sim) = sum(x -> x.color != :transparent, sim.initial_states)

function simulate(;N0=[500,500,0,0],time=1.0)
    sim = SimulationData(;N0,time)
    obs = Observable(sim)

    #
    # Setup
    #
    fig = Figure(size=(1400, 700))
    fig[1:2,1] = setup_grid = GridLayout(tellwidth=false)

    cgrid = setup_grid[1:8, 1] = [
        Label(fig, "Temperatura:", halign=:right),
        Label(fig, "k₁:", halign=:right),
        Label(fig, "k₂:", halign=:right),
        Menu(fig, options = ["Azul", "Transparente"], halign=:right),
        Menu(fig, options = ["Vermelho", "Transparente"]),
        Menu(fig, options = ["Laranja", "Transparente"]),
        Menu(fig, options = ["Verde", "Transparente"]),
        Label(fig, "tempo:", halign=:right),
    ]
    on(cgrid[4].selection) do s
        colors = obs[].colors
        colors[1] = s == "Transparente" ? :transparent : :blue
        up!(obs, :colors, colors)
    end
    on(cgrid[5].selection) do s
        colors = obs[].colors
        colors[2] = s == "Transparente" ? :transparent : :red
        up!(obs, :colors, colors)
    end
    on(cgrid[6].selection) do s
        colors = obs[].colors
        colors[3] = s == "Transparente" ? :transparent : :orange
        up!(obs, :colors, colors)
    end
    on(cgrid[7].selection) do s
        colors = obs[].colors
        colors[4] = s == "Transparente" ? :transparent : :green
        up!(obs, :colors, colors)
    end

    setup_grid[1:8, 3] = [
        Label(fig, "K", halign=:left),
        Label(fig, "mol⁻¹ s⁻¹", halign=:left),
        Label(fig, "mol⁻¹ s⁻¹", halign=:left),
        Label(fig, "", halign=:left),
        Label(fig, "", halign=:left),
        Label(fig, "", halign=:left),
        Label(fig, "", halign=:left),
        Label(fig, "min", halign=:left),
    ]
    tbw = 60 
    tb = setup_grid[1:8, 2] = [
        Textbox(fig, placeholder=@lift(string(round($(obs).temperature; digits=2))), validator=Float64, width=tbw),
        Textbox(fig, placeholder=@lift(string(round($(obs).kvec[1]; digits=2))), validator=Float64, width=tbw),
        Textbox(fig, placeholder=@lift(string(round($(obs).kvec[2]; digits=2))), validator=Float64, width=tbw),
        Textbox(fig, placeholder=@lift(string($(obs).N0[1])), validator=Int, width=tbw),
        Textbox(fig, placeholder=@lift(string($(obs).N0[2])), validator=Int, width=tbw),
        Textbox(fig, placeholder=@lift(string($(obs).N0[3])), validator=Int, width=tbw),
        Textbox(fig, placeholder=@lift(string($(obs).N0[4])), validator=Int, width=tbw),
        Textbox(fig, placeholder=@lift(string($(obs).time)), validator=Float64, width=tbw),
    ]
    on(tb[1].stored_string) do s
        up!(obs, :temperature, parse(Float32, s))
    end
    on(tb[2].stored_string) do s
        up!(obs, :kvec, [parse(Float32, s), obs[].kvec[2]])
    end
    on(tb[3].stored_string) do s
        up!(obs, :kvec, [obs[].kvec[1], parse(Float32, s)])
    end
    on(tb[4].stored_string) do s
        up!(obs, :N0, [i == 1 ? parse(Int, s) : obs[].N0[i] for i in eachindex(sim.colors)])
    end
    on(tb[5].stored_string) do s
        up!(obs, :N0, [i == 2 ? parse(Int, s) : obs[].N0[i] for i in eachindex(sim.colors)])
    end
    on(tb[6].stored_string) do s
        up!(obs, :N0, [i == 3 ? parse(Int, s) : obs[].N0[i] for i in eachindex(sim.colors)])
    end
    on(tb[7].stored_string) do s
        up!(obs, :N0, [i == 4 ? parse(Int, s) : obs[].N0[i] for i in eachindex(sim.colors)])
    end
    on(tb[8].stored_string) do s
        up!(obs, :time, parse(Float64, s))
    end

    setup_grid[8,1] = [ Label(fig, "") ]

    sb = setup_grid[9, 1] = [ Button(fig, label="Setup") ] 
    on(sb[1].clicks) do _
        setup!(fig, obs)
    end

    rb = setup_grid[9, 2] = [ Button(fig, label="Run") ] 
    on(rb[1].clicks) do _
        @async simulate!(obs)
    end

    stopb = setup_grid[9, 3] = [ Button(fig, label="Stop") ] 
    on(stopb[1].clicks) do _ 
        up!(obs, :stop, true)
    end

    colsize!(setup_grid, 1, Fixed(90))
    colsize!(setup_grid, 2, Fixed(60))
    colsize!(setup_grid, 3, Fixed(80))

    # Figure layout
    ax = Axis(fig[1:2,2], title=@lift(
            "k₁ = "*string(round($(obs).kvec[1]; digits=3))*
            " k₂ = "*string(round($(obs).kvec[2]; digits=3))*" - Step = "*string($(obs).step))
        )
    hidedecorations!(ax)

    Axis(fig[1,3]; 
        title=@lift("Histograma - N₀ = "*string($(obs).N0)),
        xlabel="Tipo",
        ylabel="Número",
        limits=@lift((0, 5, 0, yscale($obs))),
    )
    text!(fig[1,3], @lift("Q = "*string(round(compute_Q($obs);digits=5))), position=@lift((3.8, 0.90*yscale($obs))))

    Axis(fig[2,3], 
        title=@lift("Número de Moléculas - N = ["*join(get_N($obs), ", ")*"]"),
        xlabel="Tempo",
        ylabel="Número",
        limits=@lift((0, $(obs).time, 0, yscale($obs)))
    )

    # Setup simulation and plots
    setup!(fig, obs)

    colsize!(fig.layout, 1, Fixed(240))
    colsize!(fig.layout, 2, Relative(5/10))
    colsize!(fig.layout, 3, Relative(3/10))

    return fig
end

function setup!(fig, obs)

    sim = SimulationData(
        N0 = obs[].N0,
        temperature = obs[].temperature,
        time = obs[].time,
        kvec = obs[].kvec,
        colors = obs[].colors,
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
    	markersize=@lift(max(5, min(15, 5 + 1000/$(obs).box_size))),
    	color=@lift(getfield.($(obs).current_state, :color)),
    	marker=@lift(getfield.($(obs).current_state, :type)),
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
            @lift([(i*$(obs).time/$(obs).nsteps, $(obs).N_over_time[ic][i]) for i in 1:length($(obs).N_over_time[ic])]),
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
            push!(sim.N_over_time[ic], N_current[ic])
        end
        obs[].stop && break
        obs[] = SimulationData(sim)
    	sleep(1/30)
    end
    return nothing
end

include("./precompilation.jl")

end
