include("../../scripts/_scripts.jl")
include("_plotting.jl")

df_all = assemble_data("SlabDesignFactors/results/remote_results/")

plot_1_multiplot(df_all)
plot_2_megaplot(df_all)