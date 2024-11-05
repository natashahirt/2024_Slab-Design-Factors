using Pkg

# Activate the current environment
Pkg.activate(".")

# Add necessary packages
Pkg.add("Asap")
Pkg.add("AsapOptim")
Pkg.add(url="https://github.com/keithjlee/AsapToolkit")
Pkg.add("CairoMakie")
Pkg.add("ChainRulesCore")
Pkg.add("Colors")
Pkg.add("CSV")
Pkg.add("DataFrames")
Pkg.add("Interpolations")
Pkg.add("JSON")
Pkg.add("LinearSolve");
Pkg.add("Nonconvex")
Pkg.add("Statistics")
Pkg.add("StatsBase")
Pkg.add("UnPack")
Pkg.add("Zygote")

# Resolve and precompile packages
Pkg.resolve()
Pkg.precompile()
