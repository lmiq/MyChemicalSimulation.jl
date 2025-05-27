

Base.zero(::Type{ParticleState{DIM}}) where {DIM} = ParticleState{DIM}()
CellListMap.copy_output(x::ParticleState) = ParticleState(x.f, x.color, x.type)
function CellListMap.reset_output!(x::ParticleState)
	x.f = zero(typeof(x.f))
	return x
end
function CellListMap.reducer!(x::ParticleState, y::ParticleState)
	x.f += y.f
	return x
end

function update_states!(si, sj, kvec, colors)
    if (si.color == colors[1] && sj.color == colors[2]) ||
       (si.color == colors[2] && sj.color == colors[1]) ||
       (si.color == colors[3] && sj.color == colors[4]) ||
       (si.color == colors[4] && sj.color == colors[3])
        react = rand()
        k = ((si.color == colors[1]) | (sj.color == colors[1])) ? kvec[1] : kvec[2]
        if react < k
            for s in (si, sj)
                s.color == colors[1] ? s.color = colors[3] :
                s.color == colors[2] ? s.color = colors[4] :
                s.color == colors[3] ? s.color = colors[1] :
                s.color == colors[4] ? s.color = colors[2] :
                nothing
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
        f = rand(typeof(dx))
    end
	states[i].f += f
	states[j].f -= f
    update_states!(states[i], states[j], kvec, colors)
	return states
end

hit(x, v, size) = (((x <= 0) & (v < 0)) | ((x >= size) & (v > 0)))
function wall_bump(p, v, size)
    pnew = ifelse.(hit.(p, v, size), clamp.(p, 0, size),p)
    vnew = ifelse.(hit.(p, v, size), -v, v)
    return pnew, vnew
end

function thermalize!(velocities, t0)
    vmean = mean(velocities)
    velocities .-= Ref(vmean)
    t = sum(x -> sum(abs2, x), velocities)
    velocities .= sqrt(t0/t) .* velocities
    t = sum(x -> sum(abs2, x), velocities)
    return velocities, t
end