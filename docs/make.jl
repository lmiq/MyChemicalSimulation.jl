import Pkg; Pkg.add("Documenter")
using Documenter
using MyChemicalSimulation
makedocs(
    modules=[MyChemicalSimulation],
    sitename="MyChemicalSimulation.jl",
    pages = [
        "Início" => "index.md",
        "Como usar" => "using.md",
    ]
)
deploydocs(
    repo = "github.com/lmiq/MyChemicalSimulation.jl.git",
    target = "build",
    branch = "gh-pages",
    devbranch = "main", 
    versions = ["stable" => "v^", "v#.#" ],
)
