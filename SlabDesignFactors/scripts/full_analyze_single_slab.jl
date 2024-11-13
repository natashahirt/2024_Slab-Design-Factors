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
    max_depths = [25] #, 40]
    slab_sizers = [:cellular] #, :uniform]
    beam_sizers = [:discrete] #, :continuous]

    # Define the path to the JSON file containing slab geometry
    main_path = "SlabDesignFactors/jsons/topology/"  # Update this path as needed
    sub_paths = filter(x -> endswith(x, ".json"), readdir(main_path))
    sub_path = "r1c1.json"
    path = main_path * sub_path
    name = replace(sub_path, ".json" => "")

    path = "SlabDesignFactors/jsons/special/rhombus_8x12.json"  # Update this path as needed

    # Parse geometry from JSON
    geometry_dict = JSON.parse(JSON.parse(replace(read(path, String), "\\n" => ""), dicttype=Dict))
    geometry = generate_from_json(geometry_dict, plot=false, drawn=false);

    results = SlabOptimResults[]

    for max_depth in max_depths

        for slab_sizer in slab_sizers

            for beam_sizer in beam_sizers

                for (i, slab_type) in enumerate(slab_types)

                    vector_1d = vector_1ds[i]

                    # Create and analyze the slab
                    slab_params = SlabAnalysisParams(
                        geometry, 
                        slab_name=name,
                        slab_type=slab_type,
                        vector_1d=vector_1d, 
                        slab_sizer=slab_sizer,
                        spacing=.1, 
                        plot_analysis=true,
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
                        serviceability_lim=360
                    );

                    analyze_slab(slab_params)

                    @assert length(slab_params.load_areas) == length(slab_params.load_volumes) == length(slab_params.model.loads) "Mismatch in load areas and volumes."

                    #iteration_result = iterate_discrete_continuous(slab_params, beam_sizing_params);
                    #append!(results, iteration_result)

                end

            end

        end

    end

    """for result in results
        println(result.collinear)
    end

    save_results(results, subfolder = "SlabDesignFactors/results/test_results", filename = "test_improve_deflection")
    """
end