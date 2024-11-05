# Ensure the environment is activated
using Pkg
Pkg.activate(".")

# Load necessary packages for structural analysis and optimization
using Asap, AsapToolkit, AsapOptim
using CairoMakie
using Nonconvex, Zygote
using Statistics, Colors, DataFrames, CSV, JSON, Interpolations, StatsBase, UnPack

# Load optimization methods
Nonconvex.@load MMA
Nonconvex.@load NLopt

# Include necessary modules for slab analysis and optimization
include("../TributaryAreas/_TributaryAreas.jl")  # Ensure this file is correctly formatted and exists
include("../VariableBeamOptimizer/VariableBeamOptimizer.jl")

Pkg.status()

println("Initialization of Slab_Design_Factors complete")
