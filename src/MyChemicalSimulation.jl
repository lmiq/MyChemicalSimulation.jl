module MyChemicalSimulation

using GLMakie
using StaticArrays
using CellListMap
using LinearAlgebra: norm
using Statistics: mean

export initialize
export simulate

@kwdef mutable struct ParticleState
	f::SVector{2,Float32} = zero(SVector{2,Float32}) # force
	color::Symbol = :blue
	type::Symbol = :circle
end
Base.zero(::Type{ParticleState}) = ParticleState()

CellListMap.copy_output(x::ParticleState) = 
	ParticleState(x.f, x.color, x.type)
function CellListMap.reset_output!(x::ParticleState)
	x.f = zero(typeof(x.f))
	return x
end
function CellListMap.reducer!(x::ParticleState, y::ParticleState)
	x.f += y.f
	return x
end

function update_states!(si, sj, kvec, colors)
    # reacting pairs
    if (si.color == colors[1] && sj.color == colors[2]) ||
       (si.color == colors[2] && sj.color == colors[1]) ||
       (si.color == colors[3] && sj.color == colors[4]) ||
       (si.color == colors[4] && sj.color == colors[3])
        react = rand()
        k = ((si.color == colors[1]) | (sj.color == colors[1])) ? kvec[1] : kvec[2]
        if react < k
            for s in (si, sj)
                if s.color == colors[1]
                    s.color = colors[3]
                elseif s.color == colors[2]
                    s.color = colors[4]
                elseif s.color == colors[3]
                    s.color = colors[1]
                elseif s.color == colors[4]
                    s.color = colors[2]
                end
            end
        end
    end
    return si, sj
end

function update_particles!(x,y,i,j,d2,states,sys,kvec,colors)
	dx = y - x
    ndx = norm(dx)
    cutoff = sys.cutoff
    if ndx > 0
        f = 0.1f0 * (dx/ndx) * (d2 - cutoff^2)
    else
        f = rand(SVector{2,Float32})
    end
	states[i].f += f
	states[j].f -= f
    update_states!(states[i], states[j], kvec, colors)
	return states
end

function wall_bump(p, v, size)
	x, y = p[1], p[2]
	vx, vy = v[1], v[2]
	if (x <= 0 && vx < 0) | (x >= size && vx > 0) 
        x = clamp(x, 0, size)
		vx = -vx
	end
	if (y <= 0 && vy < 0) | (y >= size && vy > 0)
        y = clamp(y, 0, size)
		vy = -vy
	end
	return typeof(p)(x, y), typeof(v)(vx, vy)
end

function thermalize!(velocities, t0)
    vmean = mean(velocities)
    velocities .-= Ref(vmean)
    t = sum(x -> sum(abs2, x), velocities)
    velocities .= sqrt(t0/t) .* velocities
    t = sum(x -> sum(abs2, x), velocities)
    return velocities, t
end

function initialize(;
    N0=[500, 500, 0, 0], 
    cutoff=3.0f0, 
    nsteps=1000, 
    kvec = [0.5, 0.5], 
    colors=[:blue, :red, :green, :orange],
    dt=1.0
)
    N = sum(N0)
    box_size = 2 * sqrt(N) * cutoff
    sys = ParticleSystem(
    	xpositions= box_size .* rand(Point2f, N),
    	unitcell=Float32[box_size, box_size],
    	cutoff=cutoff,
    	output=[zero(ParticleState) for _ in 1:N],
    	output_name=:states,
    	parallel=false,
    )
    initial_positions = copy(sys.xpositions)
    sys.states .= vcat(
    	[ParticleState(;color=colors[1], type=:circle) for _ in 1:N0[1]],
    	[ParticleState(;color=colors[2], type=:star5) for _ in 1:N0[2]],
    	[ParticleState(;color=colors[3], type=:circle) for _ in 1:N0[3]],
    	[ParticleState(;color=colors[4], type=:star5) for _ in 1:N0[4]],
    )
    initial_states = deepcopy(sys.states)
    
    yscale = sum(x -> x.color != :transparent, sys.states)
    points_plot = Observable(initial_positions)
    color_plot = Observable([x.color for x in initial_states])
    step_plot = Observable("k₁ = $(kvec[1]), k₂ = $(kvec[2]) - Step = 0")
    fig = Figure(size=(1800, 1000))
    brd = round(Int, box_size/50)
    scatter(fig[1:2,1],
    	points_plot,
    	markersize=15,
    	color=color_plot,
    	marker=[x.type for x in initial_states],
        axis=(;
            limits=(-brd, box_size+brd, -brd, box_size+brd),
            title=step_plot,
        )
    )
    nblue = Observable(vcat([count(x -> x.color == colors[1], initial_states)],[0 for _ in 2:nsteps]))
    nblue_last = Observable([first(nblue[])])
    nred = Observable(vcat([count(x -> x.color == colors[2], initial_states)],[0 for _ in 2:nsteps]))
    nred_last = Observable([first(nred[])])
    ngreen = Observable(vcat([count(x -> x.color == colors[3], initial_states)], [0 for _ in 2:nsteps]))
    ngreen_last = Observable([first(ngreen[])])
    norange = Observable(vcat([count(x -> x.color == colors[4], initial_states)], [0 for _ in 2:nsteps]))
    norange_last = Observable([first(norange[])])
    barplot(fig[1,2], [1], nblue_last, color=[colors[1]],
    	axis=(; title="Histograma - N₀ = $N0", xlabel="Tipo", ylabel="Número", limits=(0, 5, 0, yscale),),
    )
    barplot!(fig[1,2], [2], nred_last, color=[colors[2]])
    barplot!(fig[1,2], [3], ngreen_last, color=[colors[3]])
    barplot!(fig[1,2], [4], norange_last, color=[colors[4]])
    q = Observable("Q = $(norange_last[][end]*ngreen_last[][end]/(nblue_last[][end]*nred_last[][end]))")
    text!(fig[1,2], q, position = (4.0, 0.95*yscale))
    time = 1:nsteps
    title_plot=Observable("Número de Moléculas - N = [$(first(nblue_last[])), $(first(nred_last[])), $(first(ngreen_last[])), $(first(norange_last[]))]")
    scatter(fig[2,2], time, nblue, color=colors[1], markersize=5,
    	axis=(;
            title=title_plot,
            xlabel="Tempo",
            ylabel="Número",
            limits=(0, nsteps, 0, yscale),
        ),
    )
    scatter!(fig[2,2], time, nred, color=colors[2], markersize=5)
    scatter!(fig[2,2], time, ngreen, color=colors[3], markersize=5)
    scatter!(fig[2,2], time, norange, color=colors[4], markersize=5)
    colsize!(fig.layout, 1, Relative(2/3))
    return fig, sys, points_plot, color_plot, step_plot, title_plot, q,
        nblue, nred, ngreen, norange, 
        nblue_last, nred_last, ngreen_last, norange_last,
        nsteps, kvec, colors, dt
end

function simulate(
        fig, sys, points_plot, color_plot, step_plot, title_plot, q,
        nblue, nred, ngreen, norange, 
        nblue_last, nred_last, ngreen_last, norange_last,
        nsteps, kvec, colors, dt
)
    N = length(sys.xpositions)
    box_size = sys.unitcell[1]
    t0 = 30f0 * sys.cutoff
    velocities = randn(SVector{2,Float32}, N)
    velocities, t = thermalize!(velocities, t0)
    for istep in 1:nsteps
    	current_states = map_pairwise!(
            (x,y,i,j,d2,out) -> update_particles!(x,y,i,j,d2,out,sys,kvec,colors), 
            sys
        )
        thermalize!(velocities, t0)
    	for i in eachindex(sys.xpositions, velocities, current_states)
    	 	pi = sys.xpositions[i]
    		vi = velocities[i]
        	pi = pi + vi * dt + current_states[i].f * dt^2
    		vi = vi + current_states[i].f * dt
    		pi, vi = wall_bump(pi, vi, box_size)
    		sys.xpositions[i] = pi
    		velocities[i] = vi
    	end
    	points_plot[] = sys.xpositions
    	color_plot[] = [x.color for x in current_states]
        step_plot[] = "k₁ = $(kvec[1]), k₂ = $(kvec[2]) - Step = $istep"
        nblue[][istep] = count(x -> x.color == colors[1], current_states)
        nblue[] = nblue[]
        nblue_last[] = [nblue[][istep]]
        nred[][istep] = count(x -> x.color == colors[2], current_states)
        nred[] = nred[]
        nred_last[] = [nred[][istep]]
        ngreen[][istep] = count(x -> x.color == colors[3], current_states)
        ngreen[] = ngreen[]
        ngreen_last[] = [ngreen[][istep]]
        norange[][istep] = count(x -> x.color == colors[4], current_states)
        norange[] = norange[]
        norange_last[] = [norange[][istep]]
        title_plot[]="Número de Moléculas - N = [$(first(nblue_last[])), $(first(nred_last[])), $(first(ngreen_last[])), $(first(norange_last[]))]"
        q[] = "Q = $(first(norange_last[])*first(ngreen_last[])/(first(nblue_last[])*first(nred_last[])))"
        display(fig)
    	sleep(1/50)
        isfile("./stop_simulation") && return "stop_simulation found!"
    end
    return nothing
end


end
