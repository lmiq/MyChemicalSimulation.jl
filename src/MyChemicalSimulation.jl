module MyChemicalSimulation

using GLMakie
using StaticArrays
using CellListMap
using LinearAlgebra: norm
using Statistics: mean

export simulate

include("./eaplot.jl")

@kwdef mutable struct ParticleState
	f::SVector{2,Float32} = zero(SVector{2,Float32}) # force
	color::Symbol = :blue
	type::Symbol = :circle
end

@kwdef mutable struct SimulationData
    N0::Vector{Int} = [500, 300, 100, 200]
    N::Int = sum(N0)
    kvec::Vector{Float64} = [0.02, 0.02]
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
    return (N3*N4)/(N1*N2), 100*(N3/(N1+N3)), 100*(N4/(N2+N4))
end

_unit(ktype) = ktype == "k" ? "mol⁻¹ s⁻¹" : "kcal mol⁻¹"
R = 1.9872e-3 # kcal/mol
Ea(k::Real,T::Real) = -R * T * log(k)
Ea(sim::SimulationData, i::Int) = Ea(sim.kvec[i], sim.temperature)
k_from_Ea(Ea, T) = exp(-Ea/(R*T))
k_or_Ea(k, T, ktype) = ktype == "k" ? k : Ea(k,T)
k_string(sim, ktype, i) = string(round(k_or_Ea(sim.kvec[i], sim.temperature, ktype[i]); digits=2))

function up!(obs::Observable, field::Symbol, value)
    sim = obs[]
    setfield!(sim, field, value)
    sim = SimulationData(
        N0 = sim.N0,
        temperature = sim.temperature,
        time = sim.time,
        kvec = sim.kvec,
        colors = sim.colors,
    )
    obs[] = sim
    return nothing
end

yscale(sim) = 1.2 * max(
    sum(x -> x.color in (:blue, :green), sim.initial_states),
    sum(x -> x.color in (:red, :orange), sim.initial_states)
)

function simulate(;N0=[500,500,0,0],time=1.0, precompile=false)
    sim = SimulationData(;N0,time)
    obs = Observable(sim)

    #
    # Setup
    #
    GLMakie.activate!(title="MyChemicalSimulation.jl")
    fig = Figure(size=(1400, 700))
    fig[1:2,1] = setup_grid = GridLayout(tellwidth=false)

    ktype = Observable(["k","k"]) # or "Ea" for each element

    cgrid = setup_grid[1:8, 1] = [
        Label(fig, "Temperatura:", halign=:right),
        Menu(fig, options = ["k₁:", "Eₐ₁:"], halign=:right),
        Menu(fig, options = ["k₂:", "Eₐ₂:"], halign=:right),
        Menu(fig, options = ["Azul", "Transparente"], halign=:right),
        Menu(fig, options = ["Vermelho", "Transparente"]),
        Menu(fig, options = ["Verde", "Transparente"]),
        Menu(fig, options = ["Laranja", "Transparente"]),
        Label(fig, "tempo:", halign=:right),
    ]
    on(cgrid[2].selection) do s
        ktype[][1] = s == "k₁:" ? "k" : "Ea"
        notify(ktype)
    end
    on(cgrid[3].selection) do s
        ktype[][2] = s == "k₂:" ? "k" : "Ea"
        notify(ktype)
    end
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
        Label(fig, @lift(_unit($(ktype)[1])), halign=:left),
        Label(fig, @lift(_unit($(ktype)[2])), halign=:left),
        Label(fig, "×10⁻³ mol", halign=:left),
        Label(fig, "×10⁻³ mol", halign=:left),
        Label(fig, "×10⁻³ mol", halign=:left),
        Label(fig, "×10⁻³ mol", halign=:left),
        Label(fig, "min", halign=:left),
    ]
    tbo(T) = (validator=T, width=60, reset_on_defocus=true) 
    tb = setup_grid[1:8, 2] = [
        Textbox(fig; placeholder=@lift(string(round($(obs).temperature; digits=2))), tbo(Float64)...),
        Textbox(fig; placeholder=@lift(k_string($obs,$ktype,1)), tbo(Float64)...),
        Textbox(fig; placeholder=@lift(k_string($obs,$ktype,2)), tbo(Float64)...),
        Textbox(fig; placeholder=@lift(string($(obs).N0[1])), tbo(Int)...),
        Textbox(fig; placeholder=@lift(string($(obs).N0[2])), tbo(Int)...),
        Textbox(fig; placeholder=@lift(string($(obs).N0[3])), tbo(Int)...),
        Textbox(fig; placeholder=@lift(string($(obs).N0[4])), tbo(Int)...),
        Textbox(fig; placeholder=@lift(string($(obs).time)), tbo(Float64)...),
    ]
    on(tb[1].stored_string) do s
        T = parse(Float32, s)
        k1 = ktype[][1] == "Ea" ? k_from_Ea(Ea(obs[].kvec[1], obs[].temperature), T) : obs[].kvec[1]
        k2 = ktype[][2] == "Ea" ? k_from_Ea(Ea(obs[].kvec[2], obs[].temperature), T) : obs[].kvec[2]
        up!(obs, :kvec, [k1, k2])
        up!(obs, :temperature, T)
    end
    on(tb[2].stored_string) do s
        val = parse(Float32, s) 
        k = ktype[][1] == "k" ? max(1e-10,min(1-1e-10, val)) : k_from_Ea(val, obs[].temperature)
        up!(obs, :kvec, [k, obs[].kvec[2]])
    end
    on(tb[3].stored_string) do s
        val = parse(Float32, s) 
        k = ktype[][2] == "k" ? max(1e-10,min(1-1e-10,val)) : k_from_Ea(val, obs[].temperature)
        up!(obs, :kvec, [obs[].kvec[1], k])
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

    rb = setup_grid[9, 1] = [ Button(fig, label="Restart") ] 
    on(rb[1].clicks) do _
        setup!(fig,obs)
    end

    rb = setup_grid[9, 2] = [ Button(fig, label="Run") ] 
    on(rb[1].clicks) do _
        @async simulate!(obs)
    end

    stopb = setup_grid[9, 3] = [ Button(fig, label="Stop") ] 
    on(stopb[1].clicks) do _ 
        sim = obs[]
        sim.stop = true
        obs[] = sim
    end

    px = -10:0.01:10
    p = @lift([create_piecewise_parabolas( [ 0.0, Ea($obs,1), Ea($obs,1) - Ea($obs,2) ], 5.0, 0.0)])
    plimits = @lift(begin
        y = map($(p)[1],px)
        ymax = Ea($obs, 1)
        yr = ymax - minimum(y)
        (-10, 10, minimum(y) - 0.25, ymax + 0.1*yr)
    end)
    ax = Axis(
            setup_grid[10, 1:3], 
            width=200,
            xticksvisible=false,
            xticklabelsvisible=false,
            ylabel="E / kcal mol⁻¹",
            limits=plimits,
            xlabel=@lift(
                "Eₐ₁ = "*string(round(Ea($(obs).kvec[1],$(obs).temperature); digits=2))*" kcal mol⁻¹\n"*
                "Eₐ₂ = "*string(round(Ea($(obs).kvec[2],$(obs).temperature); digits=2))*" kcal mol⁻¹"
            ),
    )
    scatter!(
        @lift([
            (-6, Ea($obs, 1)),
            (-4, Ea($obs, 1)),
            ( 4, Ea($obs, 1)),
            ( 6, Ea($obs, 1)),
        ]),
    	markersize=10,
    	color=@lift($(obs).colors),
    	marker=[:circle, :star5, :circle, :star5],
    )

    lines!(ax, px, @lift(map($(p)[1],px))) 
    rowsize!(setup_grid, 10, Fixed(100))

    colsize!(setup_grid, 1, Fixed(90))
    colsize!(setup_grid, 2, Fixed(60))
    colsize!(setup_grid, 3, Fixed(80))

    # Figure layout
    ax = Axis(fig[1:2,2], 
        aspect=1,
        title=@lift(
            "K = "*string(round($(obs).kvec[1]/$(obs).kvec[2];digits=3))*"; "* 
            "k₁ = "*string(round($(obs).kvec[1]; digits=4))*" mol⁻¹ s⁻¹; "*
            "k₂ = "*string(round($(obs).kvec[2]; digits=4))*" mol⁻¹ s⁻¹ "
        ),
        xlabel=@lift("\"Volume\" = "*string(round($(obs).box_size^2/1.98e6; digits=3))*" L")
    )
    hidedecorations!(ax; label=false)

    Axis(fig[1,3]; 
        title=@lift("Histograma - N₀ = "*string($(obs).N0)),
        xlabel="Tipo",
        ylabel="Número",
        limits=@lift((0, 5, 0, yscale($obs))),
    )
    Axis(fig[2,3], 
        title=@lift("Número de Moléculas - N = ["*join(get_N($obs), ", ")*"]"),
        xlabel="Tempo",
        ylabel="Número",
        limits=@lift((0, $(obs).time, 0, yscale($obs)))
    )

    # Setup simulation and plots
    setup!(fig, obs)

    q = @lift(compute_Q($obs))
    text!(fig[1,3], 
        @lift("Q = "*string(round($(q)[1];digits=3))),
        position=@lift((0.2, 0.90*yscale($obs))),
        overdraw=true,
    )
    text!(fig[1,3], 
        @lift(" α₁ = "*string(round($(q)[2];digits=2))*"%"), position=@lift((2.4, 0.90*yscale($obs))),
        overdraw=true,
    )
    text!(fig[1,3], 
        @lift(" α₂ = "*string(round($(q)[3];digits=2))*"%"), position=@lift((3.6, 0.90*yscale($obs))),
        overdraw=true,
    )

    colsize!(fig.layout, 1, Fixed(240))
    colsize!(fig.layout, 2, Relative(5/10))
    colsize!(fig.layout, 3, Relative(3/10))

    if precompile
        return fig, obs
    else
        return fig
    end
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
    	markersize=@lift(max(10, min(15, 5 + 1000/$(obs).box_size))),
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
    if sim.step > 0 
        if sim.step == sim.nsteps
            sim.nsteps *= 2
            sim.time *= 2
            nsteps_to_run = sim.nsteps
        else
            nsteps_to_run = sim.nsteps - sim.step
        end
        sim = SimulationData(sim)
        obs[] = sim
    else
        nsteps_to_run = sim.nsteps
    end

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
    istep = sim.step
    for _ in 1:nsteps_to_run
        istep += 1
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
