# analyze_single_slab.jl

# Include necessary modules
include("../SlabDesignFactors.jl")

# Activate CairoMakie for plotting
CairoMakie.activate!()

# Define the path to the JSON file containing slab geometry
path = "SlabDesignFactors/jsons/special/rhombus_8x12.json"  # Update this path as needed

# Define slab parameters
slab_type = :isotropic  # Example slab type
vector_1d = [1,1]      # Example vector
name = "rhombus_8x12"               # Name for the plot

# Parse geometry from JSON
geometry_dict = JSON.parse(JSON.parse(replace(read(path, String), "\\n" => ""), dicttype=Dict))
geometry = generate_from_json(geometry_dict, plot=false, drawn=false);

# Analyze the slab to get dimensions
slab_params = SlabAnalysisParams(
    geometry, 
    slab_name=name,
    slab_type=:uniaxial,
    vector_1d=[1,0], 
    slab_sizer=:cellular,
    spacing=.1, 
    plot_analysis=true,
    fix_param=true, 
    slab_units=:m
);

# Sizing parameters
beam_sizing_params = SlabSizingParams(
    live_load=50, # ksi
    superimposed_dead_load=15, # ksi
    live_factor=1.6,
    dead_factor=1.2,
    beam_sizer=:discrete,
    max_depth=25, # in
    beam_units=:in,
    serviceability_lim=360.0
);

slab_params = analyze_slab(slab_params);  

save("SlabDesignFactors/plot_figures/figures/tributary areas/orth_biaxial_1_1/r1c1.svg", slab_params.plot_context.fig)   

slab_params, beam_sizing_params = optimal_beamsizer(slab_params, beam_sizing_params);

slab_results_discrete_noncollinear = postprocess_slab(slab_params, beam_sizing_params, check_collinear=false);
println("Noncollinear:\n")
print_forces(slab_results_discrete_noncollinear)

slab_results_discrete_noncollinear, slab_results_discrete_collinear, slab_results_continuous_noncollinear, slab_results_continuous_collinear = iterate_discrete_continuous(slab_params, beam_sizing_params);

save_results([slab_results_discrete_noncollinear, slab_results_discrete_collinear, slab_results_continuous_noncollinear, slab_results_continuous_collinear], subfolder = "SlabDesignFactors/results/test_results", filename = "positive_load_post")
