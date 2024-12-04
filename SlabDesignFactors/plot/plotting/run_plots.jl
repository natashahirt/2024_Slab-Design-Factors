include("../../scripts/_scripts.jl")

CairoMakie.activate!()

df_all = assemble_data("SlabDesignFactors/results/processed_results/")
df_depths = assemble_data("SlabDesignFactors/results/processed_results/max_depths.csv")

save_path = "SlabDesignFactors/plot_figures/figures/"

fig = plot_1_multiplot(df_all)
save(save_path * "1_multiplot.pdf", fig)

fig = plot_2_megaplot(df_all)
save(save_path * "2_megaplot.pdf", fig)

fig = plot_3_topology(df_all, category="topology")
save(save_path * "3_topology.pdf", fig)

fig = plot_4_surface(df_all, category="grid")
save(save_path * "4_surface_grid.pdf", fig)
fig = plot_4_surface(df_all, category="nova")
save(save_path * "4_surface_nova.pdf", fig)

fig = plot_5_beam_sizes(df_all, category="topology")
save(save_path * "5_beam_sizes_topology.pdf", fig)
fig = plot_5_beam_sizes(df_all, category="grid")
save(save_path * "5_beam_sizes_grid.pdf", fig)
fig = plot_5_beam_sizes(df_all, category="nova")
save(save_path * "5_beam_sizes_nova.pdf", fig)
fig = plot_5_beam_sizes(df_all)
save(save_path * "5_beam_sizes_all.pdf", fig)

fig = plot_6_depth(df_depths)
save(save_path * "6_depth.pdf", fig)

#fig = plot_7_fix_params(df_fixed, df_unfixed)
#save(save_path * "7_fix_params.pdf", fig)

fig = plot_8_stats_summary(df_all)
save(save_path * "8_stats_summary.pdf", fig)

fig = plot_9_stats_topology(df_all)
save(save_path * "9_stats_topology.pdf", fig)

fig = plot_10_subplots(df_all, subplot=:slab_type)
save(save_path * "10_subplots_slab_type.pdf", fig)
fig = plot_10_subplots(df_all, subplot=:slab_sizer)
save(save_path * "10_subplots_slab_sizer.pdf", fig)
fig = plot_10_subplots(df_all, subplot=:beam_sizer)
save(save_path * "10_subplots_beam_sizer.pdf", fig)
fig = plot_10_subplots(df_all, subplot=:collinearity)
save(save_path * "10_subplots_collinearity.pdf", fig)
fig = plot_10_subplots(df_all, subplot=:max_depth)
save(save_path * "10_subplots_max_depth.pdf", fig)

# Plot individual slabs

path = "SlabDesignFactors/jsons/topology/r1c2.json"
name = basename(splitext(path)[1])    # Name for the plot
slab_filter = row -> row.name == name && row.slab_type == "orth_biaxial" && row.beam_sizer == "discrete" && row.vector_1d_x == 1 && row.vector_1d_y == 0 && row.slab_sizer == "uniform" && row.max_depth == 25 && row.collinear == false
test_result = slab_params = beam_sizing_params = nothing

try

    df_slab = filter(slab_filter, df_all)
    test_result = df_slab[1, :] # Get first row, can change index as needed

    # Parse geometry from JSON
    geometry_dict = JSON.parse(JSON.parse(replace(read(path, String), "\\n" => ""), dicttype=Dict));
    geometry = generate_from_json(geometry_dict, plot=false, drawn=false);

    # Analyze the slab to get dimensions
    slab_params = SlabAnalysisParams(
        geometry, 
        slab_name=name,
        slab_type=:orth_biaxial,
        vector_1d=[1,0], 
        slab_sizer=:uniform,
        spacing=.1, 
        plot_analysis=true,
        fix_param=true, 
        slab_units=:m,
    );

catch

    # Parse geometry from JSON
    geometry_dict = JSON.parse(JSON.parse(replace(read(path, String), "\\n" => ""), dicttype=Dict));
    geometry = generate_from_json(geometry_dict, plot=false, drawn=false);

    # Analyze the slab to get dimensions
    slab_params = SlabAnalysisParams(
        geometry, 
        slab_name=name,
        slab_type=:orth_biaxial,
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
        collinear=true,
        minimum_continuous=true
    );

end;

if !isnothing(test_result)
    fig = plot_slab(slab_params, test_result)
else
    println("No test result found for $name")
    fig = plot_slab(slab_params, beam_sizing_params)
end

save(save_path * "0_slab_$(name).pdf", fig)

# Fix the ids != sections bug when collinear was saved
"""# Read CSV into DataFrame first to allow modification
df = CSV.read("SlabDesignFactors/results/processed_results/nova.csv", DataFrame)

for i in 1:nrow(df)
    sections = parse_sections(String(df[i, :sections])) 
    ids = parse_sections(String(df[i, :ids]))
    if sections != ids
        df[i, :sections] = "Any[" * join(map(x -> "\"$x\"", ids), ", ") * "]"
    end
end

# Write back to CSV if needed
CSV.write("SlabDesignFactors/results/processed_results/nova.csv", df)

for row in CSV.Rows("SlabDesignFactors/results/processed_results/nova.csv")
    sections = parse_sections(String(row.sections)) # Convert PosLenString to String before parsing
    ids = parse_sections(String(row.ids))
    if sections != ids
        println(row.name)
    end
end"""