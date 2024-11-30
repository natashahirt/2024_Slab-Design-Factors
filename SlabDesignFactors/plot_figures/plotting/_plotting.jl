using DataFrames
using CSV
using Colors
using CairoMakie

include("../../core/_core.jl")
include("assemble_data.jl")
include("utils.jl")

# plot files
include("1_multiplot.jl")
include("2_megaplot.jl")
include("3_topology.jl")
include("4_surface.jl")
include("0_plot_slab.jl")
