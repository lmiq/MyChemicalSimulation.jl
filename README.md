# MyChemicalSimulation

Simula uma reação do tipo A + B -> C + D

## Como instalar

Instale a linguagem Julia de https://julialang.org/

Entre no prompt e copie e cole os comandos:

```julia
julia> import Pkg

julia> Pkg.activate("MyChemicalSimulation"; shared=true)

julia> import Pkg; Pkg.add("https://github.com/lmiq/MyChemicalSimulation.jl")

julia> using MyChemicalSimulation
```

## Como usar

```julia
julia> import Pkg

julia> Pkg.activate("MyChemicalSimulation"; shared=true)

julia> using MyChemicalSimulation

julia> simulate()
```

Isto deve abrir uma janela como esta:

[!image]("./docs/simulate.png")
