using PrecompileTools: @setup_workload, @compile_workload
@setup_workload begin
    # Putting some things in `@setup_workload` instead of `@compile_workload` can reduce the size of the
    # precompile file and potentially make loading faster.
    @compile_workload begin
        # all calls in this block will be precompiled, regardless of whether
        # they belong to your package or not (on Julia 1.8 and higher)
        fig, obs = simulate(;N0=[10,10,10,10],time=0.001,precompile=true,DIM=2)
        MyChemicalSimulation.setup!(fig, obs)
        MyChemicalSimulation.simulate!(obs)
        fig, obs = simulate(;N0=[10,10,10,10],time=0.001,precompile=true,DIM=3)
        MyChemicalSimulation.setup!(fig, obs)
        MyChemicalSimulation.simulate!(obs)
    end
end