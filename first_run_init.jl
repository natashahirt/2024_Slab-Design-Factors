using Pkg

# Activate the current environment
Pkg.activate(".")

# Add necessary packages
Pkg.add("Asap")
Pkg.add("AsapOptim")
Pkg.add(url="https://github.com/keithjlee/AsapToolkit")
Pkg.add("Statistics")
Pkg.add("Colors")
Pkg.add("CSV")
Pkg.add("JSON")
Pkg.add("DataFrames")
Pkg.add("CairoMakie")
Pkg.add("Interpolations")
Pkg.add("StatsBase")
Pkg.add("UnPack")
Pkg.add("ChainRulesCore")
Pkg.add("Nonconvex")
Pkg.add("Zygote")

# Resolve and precompile packages
Pkg.resolve()
Pkg.precompile()
