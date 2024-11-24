# Include necessary modules
include("_scripts.jl")

# Activate CairoMakie for plotting
CairoMakie.activate!()

# Define the path to the JSON file containing slab geometry
path = "SlabDesignFactors/jsons/special/rhombus_8x12.json"  # Update this path as needed
path = "SlabDesignFactors/jsons/topology/r1c2.json"

name = basename(splitext(path)[1])    # Name for the plot

# Parse geometry from JSON
geometry_dict = JSON.parse(JSON.parse(replace(read(path, String), "\\n" => ""), dicttype=Dict))
geometry = generate_from_json(geometry_dict, plot=false, drawn=false);

# Analyze the slab to get dimensions
slab_params = SlabAnalysisParams(
    geometry, 
    slab_name=name,
    slab_type=:isotropic,
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

slab_params = analyze_slab(slab_params);
slab_params, beam_sizing_params = optimal_beamsizer(slab_params, beam_sizing_params);
slab_results_discrete_noncollinear = postprocess_slab(slab_params, beam_sizing_params, check_collinear=false);
print_forces(slab_results_discrete_noncollinear)

slab_results_discrete_noncollinear, slab_results_discrete_collinear, slab_results_continuous_noncollinear, slab_results_continuous_collinear = iterate_discrete_continuous(slab_params, beam_sizing_params);
save_results([slab_results_discrete_noncollinear, slab_results_discrete_collinear, slab_results_continuous_noncollinear, slab_results_continuous_collinear], subfolder = "SlabDesignFactors/results/test_results", filename = "test_binary_search")

#save("SlabDesignFactors/plot_figures/figures/tributary areas/orth_biaxial_1_1/r1c1.svg", slab_params.plot_context.fig)   

for (i,minimizer) in enumerate(beam_sizing_params.minimizers)
    section = I_symm(minimizer...)
    loads = beam_sizing_params.load_dictionary[get_element_id(beam_sizing_params.model.elements[:beam][i])]
    load_values = [load.value[3] for load in loads]
    if isempty(load_values)
        load_values = 0
    end
    println("Sum of loads: $(sum(load_values))... A: $(section.A)")
end

slab_results_discrete_noncollinear = postprocess_slab(slab_params, beam_sizing_params, check_collinear=false);
print_forces(slab_results_discrete_noncollinear)

GC.gc()
