# analyze_single_slab.jl

begin    
    # Include necessary modules
    include("_scripts.jl")

    # Activate CairoMakie for plotting
    CairoMakie.activate!()
    
    # Define the path to the JSON file containing slab geometry
    main_path = "SlabDesignFactors/jsons/topology/"  # Update this path as needed
    sub_paths = filter(x -> endswith(x, ".json"), readdir(main_path))
    sub_path = "r1c2.json"
    path = joinpath(main_path, sub_path)
    name = replace(sub_path, ".json" => "")

    # define path for saving results
    results_path = "SlabDesignFactors/results/remote_results_min/"
    results_name = name

    # Define slab parameters
    slab_types = [:isotropic, :orth_biaxial, :orth_biaxial, :uniaxial, :uniaxial, :uniaxial, :uniaxial]         # Slab types
    vector_1ds = [[0.0, 0.0,], [1.0, 0.0,], [1.0, 1.0,], [1.0, 0.0,], [0.0, 1.0,], [1.0, 1.0,], [1.0, -1.0,]]    # Vectors
    max_depths = [25, 40]
    slab_sizers = [:cellular, :uniform]
    beam_sizers = [:discrete, :continuous]

    # Parse geometry from JSON
    geometry_dict = JSON.parse(JSON.parse(replace(read(path, String), "\\n" => ""), dicttype=Dict))
    geometry = generate_from_json(geometry_dict, plot=false, drawn=false);

    results = SlabOptimResults[]

    for max_depth in max_depths

        for slab_sizer in slab_sizers

            for (i, slab_type) in enumerate(slab_types)

                vector_1d = vector_1ds[i]

                # Check if this configuration already exists in results file
                results_file = results_path * results_name * ".csv"
                if isfile(results_file)
                    existing_df = CSV.read(results_file, DataFrame)
                    if any((existing_df.max_depth .== max_depth) .&
                            (existing_df.slab_sizer .== string(slab_sizer)) .& 
                            (existing_df.slab_type .== string(slab_type)) .&
                            (existing_df.vector_1d_x .== vector_1d[1]) .&
                            (existing_df.vector_1d_y .== vector_1d[2]))
                        println("Already analyzed $(name) for $(slab_type) $(vector_1d) $(slab_sizer) $(max_depth) in.")
                        continue
                    end
                end

                println("================================================")
                println("$(name): $(slab_type) $(vector_1d) $(slab_sizer) $(max_depth)in")
                println("================================================")

                # Create and analyze the slab
                slab_params = SlabAnalysisParams(
                    geometry, 
                    slab_name=name,
                    slab_type=slab_type,
                    vector_1d=vector_1d, 
                    slab_sizer=slab_sizer,
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
                    beam_sizer=:discrete, # iteration runs through both discrete and continuous
                    max_depth=max_depth, # in
                    beam_units=:in, # in, etc.
                    serviceability_lim=360,
                    collinear=false,
                    minimum_continuous=true
                );

                iteration_result = collect(iterate_discrete_continuous(slab_params, beam_sizing_params));
                
                append_results_to_csv(results_path, results_name, iteration_result)

            end

        end

    end

end