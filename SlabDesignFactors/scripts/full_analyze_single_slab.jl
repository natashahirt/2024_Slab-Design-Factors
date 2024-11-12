# analyze_single_slab.jl

# Include necessary modules
include("../SlabDesignFactors.jl")

# Activate CairoMakie for plotting
CairoMakie.activate!()

begin

    # Define loads
    load_ksi = (1.6 * 50 + 1.2 * 15) / (1e3 * 12^2)  # Live + superimposed dead load, ksi, factored
    load_kNm2 = load_ksi * 6895                      # Convert to kN/m²

    # Define slab parameters
    slab_types = [:isotropic, :orth_biaxial, :orth_biaxial, :uniaxial, :uniaxial, :uniaxial, :uniaxial]         # Slab types
    vector_1ds = [[1.0, 0.0,], [1.0, 0.0,], [1.0, 1.0,], [1.0, 0.0,], [0.0, 1.0,], [1.0, 1.0,], [1.0, -1.0,]]    # Vectors
    max_depths = [25, 40]
    slab_sizers = [:cellular, :uniform]
    beam_sizers = [:discrete, :continuous]

    # Define the path to the JSON file containing slab geometry
    main_path = "SlabDesignFactors/jsons/topology/"  # Update this path as needed
    sub_paths = filter(x -> endswith(x, ".json"), readdir(main_path))
    sub_path = "r1c1.json"
    path = main_path * sub_path
    name = replace(sub_path, ".json" => "")

    # Parse geometry from JSON
    geometry_dict = JSON.parse(JSON.parse(replace(read(path, String), "\\n" => ""), dicttype=Dict))
    geometry = generate_from_json(geometry_dict, plot=false, drawn=false);

    results = SlabOptimResults[]

    for max_depth in max_depths

        for slab_sizer in slab_sizers

            for beam_sizer in beam_sizers

                for (i, slab_type) in enumerate([slab_types[1]])

                    vector_1d = vector_1ds[i]

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
                        slab_sizer=slab_sizer, 
                        beam_sizer=beam_sizer, 
                    );

                    beam_sizing_params = SlabSizingParams(
                        max_depth=max_depth, 
                        sizing_unit=:in, 
                        deflection_limit=true, 
                        verbose=false, 
                        minimum=false, 
                        max_assembly_depth=true
                    )

                    iteration_result = iterate_discrete_continuous(slab_params, beam_sizing_params);
                    append!(results, iteration_result)

                end

            end

        end

    end

    for result in results
        println(result.collinear)
    end

    save_results(results, subfolder = "SlabDesignFactors/results/test_results", filename = "test_improve_deflection")

end