# analyze_single_slab.jl

using Base.Threads

function analyze_all_jsons(results_path::String)

    include("../SlabDesignFactors.jl")
    println("Dependencies loaded successfully.")

    # Read parameters from file
    params_file = "/home/nhirt/2024_Slab-Design-Factors/SlabDesignFactors/executable/params.txt"
    params_lines = readlines(params_file)

    # Function to process a single set of parameters
    function process_params(line)

        # Get the JSON path and results name
        split_line = split(line, " ")
        json_path = split_line[1]
        results_name = split_line[2]

        println("Analyzing all JSONs in $(json_path)")
        println("Saving results to $(results_path)")
        println("Results name: $(results_name)")

        # Define slab parameters
        slab_types = [:isotropic, :orth_biaxial, :orth_biaxial, :uniaxial, :uniaxial, :uniaxial, :uniaxial]         # Slab types
        vector_1ds = [[0.0, 0.0,], [1.0, 0.0,], [1.0, 1.0,], [1.0, 0.0,], [0.0, 1.0,], [1.0, 1.0,], [1.0, -1.0,]]    # Vectors
        max_depths = [25, 40]
        slab_sizers = [:cellular, :uniform]

        # Define the path to the JSON file containing slab geometry
        sub_paths = filter(x -> endswith(x, ".json"), readdir(json_path))
        println(sub_paths)
        
        # Evaluate slabs
        for max_depth in max_depths

            for slab_sizer in slab_sizers

                for (i, slab_type) in enumerate(slab_types)

                    vector_1d = vector_1ds[i]

                    # Check if this configuration already exists in results file
                    results_file = results_path * results_name * ".csv"

                    for sub_path in sub_paths

                        path = json_path * sub_path
                        name = replace(sub_path, ".json" => "")  

                        if isfile(results_file)
                            existing_df = CSV.read(results_file, DataFrame)
                            if any((existing_df.name .== name) .&
                                    (existing_df.max_depth .== max_depth) .&
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

                        # Parse geometry from JSON
                        geometry_dict = JSON.parse(JSON.parse(replace(read(path, String), "\\n" => ""), dicttype=Dict))
                        geometry = generate_from_json(geometry_dict, plot=false, drawn=false);

                        # Create and analyze the slab
                        slab_params = SlabAnalysisParams(
                            geometry, 
                            slab_name=name,
                            slab_type=slab_type,
                            vector_1d=vector_1d, 
                            slab_sizer=slab_sizer,
                            spacing=.1, 
                            plot_analysis=false,
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
                            minimum_continuous=true
                        );

                        iteration_result = collect(iterate_discrete_continuous(slab_params, beam_sizing_params));
                    
                        append_results_to_csv(results_path, results_name, iteration_result)

                        GC.gc() # garbage collect

                    end

                end

            end

        end

    end

    @threads for line in params_lines
        process_params(line)
    end

end

# Main execution
function main()
    args = ARGS
    if length(args) != 1
        println("Usage: julia executable_analyze.jl <results_path>")
        return
    end

    results_path = args[1]
    analyze_all_jsons(results_path)
end

main()