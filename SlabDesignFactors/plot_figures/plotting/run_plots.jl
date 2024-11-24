include("_plotting.jl")

df_all = assemble_data("SlabDesignFactors/results/remote_results/")

plot_1_multiplot(df_all)
plot_2_megaplot(df_all)

bau_filter = row -> row.name == "r1c2" && row.slab_type == "isotropic" && row.beam_sizer == "discrete" && row.collinear
println(filter(bau_filter, df_all))