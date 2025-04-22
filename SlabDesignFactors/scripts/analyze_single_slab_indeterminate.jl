# Include necessary modules
include("_scripts.jl")

# Activate CairoMakie for plotting
CairoMakie.activate!()

# Define the path to the JSON file containing slab geometry
#path = "Geometries/special/topopt_test1.json"  # Update this path as needed
#path = "Geometries/nova/e4c4.json"

name = basename(splitext(path)[1])    # Name for the plot
name = "topopt_test1_demo"
# Parse geometry from JSON
geometry_dict = JSON.parse(JSON.parse(replace(read(path, String), "\\n" => ""), dicttype=Dict))
geometry = generate_from_json(geometry_dict, plot=true, drawn=false);

h = 8
w = 12
resolution = 10
geometry = generate_ground_structure(h, w, resolution, plot=true);
name = "ground_structure_$(h)_$(w)_$(resolution)"

slab_params = SlabAnalysisParams(
    geometry, 
    slab_name=name,
    slab_type=:isotropic,
    load_type=:indeterminate,
    vector_1d=[0,1], 
    slab_sizer=:uniform,
    spacing=.1, 
    plot_analysis=false,
    fix_param=true, 
    slab_units=:m,
);

# Sizing parameters
beam_sizing_params = SlabSizingParams(
    live_load=psf_to_ksi(60), # ksi
    superimposed_dead_load=psf_to_ksi(20), # ksi
    live_factor=1.6, # -
    dead_factor=1.2, # -
    beam_sizer=:continuous,
    max_depth=40, # in
    beam_units=:in, # in, etc.
    serviceability_lim=360,
    collinear=false,
    minimum_continuous=false,
    n_max_sections=0,
    deflection_limit=false,
);

# Get unique coordinates from raster_df centerpoint_coords
slab_params = analyze_slab(slab_params);
get_raster_df(slab_params; resolution=50)
"""process_continuous_beams_topopt(slab_params, beam_sizing_params)

design_variables = vcat([get_geometry_vars(W_imperial("W8X35")) for _ in 1:length(slab_params.model.elements[:beam])]...)

for (i,element) in enumerate(slab_params.model.elements[:beam])
    I_symm_section = I_symm(design_variables[4*i-3:4*i]...)
    asap_section = Section(I_symm_section.A, steel_ksi.E, steel_ksi.G, I_symm_section.Ix, I_symm_section.Iy, I_symm_section.J)
    element.section = asap_section
end

slab_params, beam_sizing_params = optimal_beamsizer(slab_params, beam_sizing_params);
results = postprocess_slab(slab_params, beam_sizing_params);
objective_variables = [results.embodied_carbon_slab, results.embodied_carbon_beams]"""

# REDISTRIBUTION

slab_params = analyze_slab(slab_params);
slab_params, beam_sizing_params = optimal_beamsizer(slab_params, beam_sizing_params);
results_standard_optimization = postprocess_slab(slab_params, beam_sizing_params);
results_standard_optimization.embodied_carbon_beam
centerpoint_coords = identify_raster_points(slab_params, 5)
scatter(Point2f.(centerpoint_coords), color=:red, markersize=8, axis=(limits=(0, 12, 0, 10),))

for loop in 1:10

    # Create directory if it doesn't exist
    dir = "Documentation/250327_Topopt Loop $(slab_params.slab_name)"
    mkpath(dir)

    function get_volume(minimizers, model)
        return sum([I_symm(minimizers[i]...).A * model.elements[:beam][i].length for i in 1:lastindex(minimizers)])
    end

    results_list = []
    slab_params_topopt = analyze_slab(slab_params)

    for i in 1:10
        slab_params_topopt = calculate_slab_loads_indeterminate(slab_params_topopt)

        if i == 1
            results_list = []
            initial_vars = [get_geometry_vars(W_imperial("W6X8.5")) for _ in 1:length(slab_params_topopt.model.elements[:beam])]
        elseif i == 2
            initial_vars = results_list[i-1].minimizers
        else
            blend_ratio = 0.5
            initial_vars = [
                blend_ratio .* results_list[i-1].minimizers[j] .+ (1 - blend_ratio) .* results_list[i-2].minimizers[j]
                for j in 1:length(results_list[i-1].minimizers)
            ]
        end

        slab_params_topopt, beam_sizing_params = optimal_beamsizer(slab_params_topopt, beam_sizing_params, initial_vars = initial_vars) # differentiable, uses Ipopt

        for (i,element) in enumerate(slab_params_topopt.model.elements[:beam])
            I_symm_section = I_symm(beam_sizing_params.minimizers[i]...)
            asap_section = Section(I_symm_section.A, steel_ksi.E, steel_ksi.G, I_symm_section.Ix, I_symm_section.Iy, I_symm_section.J)
            element.section = asap_section
        end

        results = beam_sizing_params
        push!(results_list, results)

        if i > 1    
            if abs(get_volume(results.minimizers, slab_params_topopt.model) - get_volume(results_list[i-1].minimizers, slab_params.model)) / get_volume(results_list[i-1].minimizers, slab_params.model) < 0.01
                println("Converged at iteration $i")
                break
            end
        end

        result_volume = get_volume(results.minimizers, slab_params_topopt.model)
        println("Volume beams: $(result_volume)")
        fig = plot_slab(slab_params_topopt, results_list[end], text=false, mini=false, background=false, collinear=false)
        
        save("$dir/$(result_volume)_Iteration_$(i).png", fig)
        println("--------------------")
    end

    slab_params, beam_sizing_params = optimize_indeterminate(slab_params, beam_sizing_params, initial_vars = results_list[end].minimizers);
    
    results = beam_sizing_params
    push!(results_list, results)
    
    result_volume = get_volume(beam_sizing_params.minimizers, slab_params.model)
    println("Volume beams: $(result_volume)")
    fig = plot_slab(slab_params, beam_sizing_params, text=false, mini=false, background=false, collinear=false)
    
    save("$dir/$(result_volume)_Iteration_Topopt.png", fig)

end


slab_params_topopt, beam_sizing_params_topopt = optimize_indeterminate(slab_params, beam_sizing_params, initial_vars = results_list[end].minimizers);
fig = plot_slab(slab_params_topopt, beam_sizing_params_topopt, text=false, mini=false, background=false, collinear=false)


for result in results_list
    volume = get_volume(result.minimizers, slab_params.model)
    println(volume)
end


function optimize_beam_sections(slab_params, beam_sizing_params)

    slab_params = analyze_slab(slab_params);

    model = slab_params.model
    beam_elements = model.elements[:beam]
    default_section = W_imperial("W8X35")
    
    design_variables = vcat([get_geometry_vars(default_section) for _ in 1:length(beam_elements)]...)

    function objective(design_variables)
        i_sections = [I_symm(design_variables[4*i-3:4*i]...) for i in 1:length(beam_elements)]
        
        for (i, element) in enumerate(slab_params.model.elements[:beam])
            section = Section(i_sections[i].A, steel_ksi.E, steel_ksi.G, i_sections[i].Ix, i_sections[i].Iy, i_sections[i].J)
            
            # Ensure non-negative area and moments of inertia
            if section.A < 0 || section.Ix < 0 || section.Iy < 0 || section.J < 0
                println("Warning: Negative area or moment of inertia detected. Applying penalty.")
                return Inf  # Return a large penalty value
            end
            
            element.section = section
        end

        slab_params = calculate_slab_loads_indeterminate(slab_params)
        slab_params, beam_sizing_params = optimal_beamsizer(slab_params, beam_sizing_params, initial_vars = [design_variables[4*i-3:4*i] for i in 1:length(beam_elements)])
        
        A = [A_I_symm(vars...) for vars in beam_sizing_params.minimizers]
        
        total_volume = sum(A[i] * beam_elements[i].length for i in 1:length(beam_elements))
        
        return total_volume
    end

    if beam_sizing_params.minimum_continuous == true
        min_h, min_w, min_tw, min_tf = get_geometry_vars(W_imperial("W6X8.5"))
    else
        min_h, min_w, min_tw, min_tf = [0.01, 0.01, 0.001, 0.001]
    end

    max_h, max_w, max_tw, max_tf = get_geometry_vars(W_imperial("W43X335"))

    bounds = [(min_h, max_h), (min_w, max_w), (min_tw, max_tw), (min_tf, max_tf)]

    search_range = [(Float64(min), Float64(max)) for (min, max) in repeat(bounds, length(beam_elements))]

    result = bboptimize(objective, SearchRange=search_range, MaxSteps=3600, Method=:adaptive_de_rand_1_bin_radiuslimited)

    return beam_sizing_params

end

using BlackBoxOptim
beam_sizing_params_topopt = optimize_beam_sections(slab_params, beam_sizing_params);

results_topopt = postprocess_slab(slab_params_topopt, beam_sizing_params_topopt);
results_topopt.embodied_carbon_beams

results_topopt.minimizers
print_forces(results_topopt)

areas = sum([I_symm(results_topopt.minimizers[i]...).A for i in 1:n_beams])

fig = plot_slab(slab_params_topopt, beam_sizing_params_topopt, text=false, mini=false, background=false, collinear=false)

volumes = sum([I_symm(beam_sizing_params_topopt.minimizers[i]...).A * beam_sizing_params_topopt.model.elements[:beam][i].length * 1/convert_to_m[:in] for i in 1:n_beams])

sum(results_areas)
sum(results_parallel_areas)
sum(results_2_areas)

slab_params = analyze_slab(slab_params);
slab_params, beam_sizing_params = optimal_beamsizer(slab_params, beam_sizing_params, initial_vars = results_topopt.minimizers);
beam_sizing_params_volumes = [I_symm(beam_sizing_params.minimizers[i]...).A * beam_sizing_params.model.elements[:beam][i].length for i in 1:n_beams]
sum(beam_sizing_params_volumes)

results = postprocess_slab(slab_params, beam_sizing_params);
volume_optimized = sum([I_symm(results.minimizers[i]...).A * beam_sizing_params.model.elements[:beam][i].length * 1/convert_to_m[:in] for i in 1:n_beams])
sum([I_symm(results.minimizers[i]...).A for i in 1:n_beams])
print_forces(results)
results.minimizers
results.embodied_carbon_beams

fig = plot_slab(slab_params, beam_sizing_params, text=false, mini=false, background=false, collinear=false)