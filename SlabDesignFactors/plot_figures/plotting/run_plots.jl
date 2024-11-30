include("../../scripts/_scripts.jl")
include("_plotting.jl")

df_all = assemble_data("SlabDesignFactors/results/processed_results/")

plot_1_multiplot(df_all)
plot_2_megaplot(df_all)
plot_3_topology(df_all, category="topology")
plot_4_surface(df_all, category="grid")
plot_5_beam_sizes(df_all, category="topology")
plot_6_depth(df_depths)
plot_7_fix_params(df_fixed, df_unfixed)
plot_8_stats_summary(df_all)
plot_9_stats_topology(df_all)

# Plot individual slabs

path = "SlabDesignFactors/jsons/special/triple_bay_drawn.json"
name = basename(splitext(path)[1])    # Name for the plot
slab_filter = row -> row.name == name && row.slab_type == "uniaxial" && row.beam_sizer == "discrete" && row.vector_1d_x == 1 && row.vector_1d_y == 0 && row.slab_sizer == "uniform" && row.max_depth == 25 && row.collinear == true
df_slab = filter(slab_filter, df_all)
test_result = df_slab[1, :] # Get first row, can change index as needed

# Parse geometry from JSON
geometry_dict = JSON.parse(JSON.parse(replace(read(path, String), "\\n" => ""), dicttype=Dict))
geometry = generate_from_json(geometry_dict, plot=false, drawn=true);

# Analyze the slab to get dimensions
slab_params = SlabAnalysisParams(
    geometry, 
    slab_name=name,
    slab_type=:uniaxial,
    vector_1d=[1,0], 
    slab_sizer=:uniform,
    spacing=.1, 
    plot_analysis=true,
    fix_param=true, 
    slab_units=:m,
);

# Sizing parameters
beam_sizing_params = SlabSizingParams(
    live_load=psf_to_ksi(50), # ksi
    superimposed_dead_load=psf_to_ksi(15), # ksi
    live_factor=1.6, # -
    dead_factor=1.2, # -
    beam_sizer=:discrete,
    max_depth=25, # in
    beam_units=:in, # in, etc.
    serviceability_lim=360,
    collinear=false,
    minimum_continuous=true
);

plot_slab(slab_params, beam_sizing_params)
