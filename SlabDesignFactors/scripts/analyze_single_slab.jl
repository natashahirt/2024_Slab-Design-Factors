# analyze_single_slab.jl

# Include necessary modules
include("../SlabDesignFactors.jl")

# Activate CairoMakie for plotting
CairoMakie.activate!()

# Define the path to the JSON file containing slab geometry
path = "SlabDesignFactors/jsons/special/rhombus_8x12.json"  # Update this path as needed

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
    slab_type, 
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
save_results([slab_results_discrete_noncollinear, slab_results_discrete_collinear, slab_results_continuous_noncollinear, slab_results_continuous_collinear], subfolder = "SlabDesignFactors/results/test_results", filename = "positive_load_post")