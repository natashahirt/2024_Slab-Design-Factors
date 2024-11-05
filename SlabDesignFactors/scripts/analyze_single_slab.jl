# analyze_single_slab.jl

# Include necessary modules
include("SlabDesignFactors/_SlabDesignFactors.jl")

# Activate CairoMakie for plotting
CairoMakie.activate!()

# Define the path to the JSON file containing slab geometry
path = "Tributary Areas/jsons/special/rhombus_8x12.json"  # Update this path as needed

# Define slab parameters
slab_type = :uniaxial  # Example slab type
vector_1d = [1.0, 1.0]      # Example vector
name = "rhombus_8x12"               # Name for the plot
highlight = 1               # Element to highlight in the plot

# Load and factor the load
load_ksi = (1.6 * 50 + 1.2 * 10) / (1e3 * 12^2)  # Live + dead load, ksi, factored
load_kNm2 = load_ksi * 6895                      # Convert to kN/m²

# Parse geometry from JSON
geometry_dict = JSON.parse(JSON.parse(replace(read(path, String), "\\n" => ""), dicttype=Dict))
geometry = generate_from_json(geometry_dict, plot=false, drawn=false);

# Create and analyze the slab
slab_params = SlabAnalysisParams(
    geometry, 
    :isotropic, 
    slab_name=name,
    vector_1d=vector_1d, 
    spacing=.1, 
    w=load_kNm2, 
    plot_analysis=true,
    fix_param=true, 
    slab_sizer=:cellular, 
    beam_sizer=:discrete, 
);

beam_sizing_params = BeamSizingParams(
    max_depth=40, 
    sizing_unit=:in, 
    deflection_limit=true, 
    verbose=false, 
    minimum=false, 
    max_assembly_depth=true
)

slab_results_discrete_noncollinear, slab_results_discrete_collinear, slab_results_continuous_noncollinear, slab_results_continuous_collinear = iterate_discrete_continuous(slab_params, beam_sizing_params, save=false);
save_results([slab_results_discrete_noncollinear, slab_results_discrete_collinear, slab_results_continuous_noncollinear, slab_results_continuous_collinear], subfolder = "Tributary Areas/results/test_results", filename = "verify")

# ================================================================

# Parse geometry from JSON
geometry_dict = JSON.parse(JSON.parse(replace(read(path, String), "\\n" => ""), dicttype=Dict))
geometry = generate_from_json(geometry_dict, plot=true, drawn=false);

# Create and analyze the slab
slab_params = SlabAnalysisParams(
    geometry, 
    slab_type, 
    slab_name=name,
    vector_1d=vector_1d, 
    spacing=0.1, 
    w=load_kNm2, 
    plot_analysis=true,
    fix_param=false, 
    slab_sizer=:uniform, 
    beam_sizer=:discrete,
);

beam_sizing_params = BeamSizingParams(
    max_depth=40, 
    sizing_unit=:in, 
    deflection_limit=true, 
    verbose=false, 
    minimum=false, 
    max_assembly_depth=true
)

# Optimize beam sizes discrete
slab_params = analyze_slab(slab_params);
slab_params, beam_sizing_params = optimal_beamsizer(slab_params, beam_sizing_params);
initial_sections = [to_ASAP_section(I_symm(minimizer...)) for minimizer in beam_sizing_params.minimizers]
initial_vars = beam_sizing_params.minimums
println(slab_params.beam_sizer)
slab_results_discrete = postprocess_slab(slab_params, beam_sizing_params, check_collinear=true);
print_forces(slab_results_discrete)
println(slab_results_discrete.self.beam_sizer)

# Optimize beam sizes continuous
slab_params.beam_sizer = :continuous
beam_sizing_params = reset_BeamSizingParams(beam_sizing_params)
slab_params, beam_sizing_params = optimal_beamsizer(slab_params, beam_sizing_params, initial_vars=initial_vars);
slab_results_continuous = postprocess_slab(slab_params, beam_sizing_params, check_collinear=false);
print_forces(slab_results_continuous)


# Plot forces
highlight = 1
fig = plot_forces(slab_results, :A, highlight=highlight, name=name, override=false)

# Save the plot
save("results/figures/slab_plot.pdf", fig)

# Output the results
println("Analysis and plotting complete. Results saved to 'results/figures/slab_plot.pdf'.")
