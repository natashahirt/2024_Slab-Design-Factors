# Include necessary modules
include("_scripts.jl")

# Activate CairoMakie for plotting
CairoMakie.activate!()

# Define the path to the JSON file containing slab geometry
path = "Geometries/special/star_8x12.json"  # Update this path as needed
# path = "Geometries/nova/e4c4.json"

name = basename(splitext(path)[1])    # Name for the plot
# Parse geometry from JSON
geometry_dict = JSON.parse(JSON.parse(replace(read(path, String), "\\n" => ""), dicttype=Dict))
geometry = generate_from_json(geometry_dict, plot=true, drawn=false);

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
    collinear=true,
    minimum_continuous=false,
    n_max_sections=0,
);


process_continuous_beams_topopt(slab_params, beam_sizing_params)



design_variables = vcat([get_geometry_vars(W_imperial("W8X35")) for _ in 1:length(slab_params.model.elements[:beam])]...)

for (i,element) in enumerate(slab_params.model.elements[:beam])
    I_symm_section = I_symm(design_variables[4*i-3:4*i]...)
    asap_section = Section(I_symm_section.A, steel_ksi.E, steel_ksi.G, I_symm_section.Ix, I_symm_section.Iy, I_symm_section.J)
    element.section = asap_section
end

slab_params, beam_sizing_params = optimal_beamsizer(slab_params, beam_sizing_params);
results = postprocess_slab(slab_params, beam_sizing_params);
objective_variables = [results.embodied_carbon_slab, results.embodied_carbon_beams]
results_list = []

begin
    for i in 1:10
        slab_params = calculate_slab_loads_indeterminate(slab_params)

        if i == 1
            results_list = []
            initial_vars = [get_geometry_vars(W_imperial("W8X35")) for _ in 1:length(slab_params.model.elements[:beam])]
        else
            initial_vars = results_list[i-1].minimizers
        end

        slab_params, beam_sizing_params = optimal_beamsizer(slab_params, beam_sizing_params, initial_vars = initial_vars) # differentiable, uses Ipopt

        for (i,element) in enumerate(slab_params.model.elements[:beam])
            I_symm_section = I_symm(beam_sizing_params.minimizers[i]...)
            asap_section = Section(I_symm_section.A, steel_ksi.E, steel_ksi.G, I_symm_section.Ix, I_symm_section.Iy, I_symm_section.J)
            element.section = asap_section
        end

        results = beam_sizing_params

        push!(results_list, results)
        println("--------------------")
    end

end

for result in results_list
    volume = sum([I_symm(result.minimizers[i]...).A * slab_params.model.elements[:beam][i].length for i in 1:lastindex(result.minimizers)])
    println(volume)
end

fig = plot_slab(slab_params, results_list[end], text=false, mini=false, background=false, collinear=false)
postprocessed = postprocess_slab(slab_params, results_list[end]);
println(postprocessed.embodied_carbon_beams)



function optimize_beam_sections(slab_params, beam_sizing_params)

    slab_params = analyze_slab(slab_params);

    model = slab_params.model
    beam_elements = model.elements[:beam]
    default_section = W_imperial("W8X35")
    
    design_variables = vcat([get_geometry_vars(default_section) for _ in 1:length(beam_elements)]...)

    function objective(design_variables)

        i_sections = [I_symm(design_variables[4*i-3:4*i]...) for i in 1:length(beam_elements)]
    
        for (i,element) in enumerate(slab_params.model.elements[:beam])
            section = Section(i_sections[i].A, steel_ksi.E, steel_ksi.G, i_sections[i].Ix, i_sections[i].Iy, i_sections[i].J)
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

beam_sizing_params = optimize_beam_sections(slab_params, beam_sizing_params);
fig = plot_slab(slab_params, beam_sizing_params, text=false, mini=false, background=false, collinear=false)
