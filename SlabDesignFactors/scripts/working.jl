include("_slab_script.jl")

# from beamsizer script
"""
test!
"""

load_ksi = (40 + 10) / (1e3 * 12^2) # live + dead, ksi
load_kNm2 = load_ksi * 6895 # kN/m^2, typical slab load in residential buildings ~ 1.5, offices ~ 5
geometry = generate_rectangle(12,8,4);
#geometry = generate_regular_polygon(10,5)
#index = 10
#geometry = generate_rozvany(10.,index=1);
#geometry = generate_unfunky_test(8, 12)
row = 7
col = 4
#path = "/Users/tashahirt/Dropbox (MIT)/_MIT/Digital Structures Research/Tributary Areas/geometry_jsons/" * "r" * string(row) * "c" * string(col) * ".json"
path = "/Users/tashahirt/Dropbox (MIT)/_MIT/Digital Structures Research/Tributary Areas/_special_jsons/triple_bay_drawn.json"
geometry_dict = JSON.parse(JSON.parse(replace(read(path,String),"\\n"=>""), dicttype=Dict));
geometry = generate_from_json(geometry_dict,plot=true);
slab = SlabAnalysisParams(geometry, :uniaxial, vector_1d=[1.,0.], spacing=0.1, w=load_kNm2, plot_analysis=true,
                                fix_param=true, slab_sizer=:uniform, beam_sizer=:discrete, collinear=true); # original load was 7e3 kN/m²
@time slab = analyze_slab(slab);

# load on the beams is given in kips/in
@time minimizers, minimums, ids = optimal_beamsizer(slab, max_depth = 40, deflection_limit=true, minimum=false);

"""try
    minimizers, minimums, ids = optimal_beamsizer!(slab, ids, max_depth = 40, deflection_limit=true, verbose=false, minimum=false)
catch e
    print(e)
end

iterate_beamsizer(slab, geometry_dict, max_depth=40, n_iter=5)

iterate_discrete_continuous(slab, geometry_dict, max_depth=40)"""

# visualisation and printing
slab_results = postprocess_slab(slab, minimizers, minimums, ids, check_collinear=true);
print_forces(slab_results)

results_list_noncollinear = SlabOptimResults[]
results_list_collinear = SlabOptimResults[]

# postprocess
println("\nNoncollinear")
results_noncollinear = postprocess_slab(slab, minimizers, minimums, ids, check_collinear=false);
push!(results_list_noncollinear, results_noncollinear);
print_forces(results_noncollinear)

println("\ncollinear")
results_collinear = postprocess_slab(slab, minimizers, minimums, ids, check_collinear=true);
push!(results_list_collinear, results_collinear);
print_forces(results_collinear)

println(results_noncollinear.minimizers)
println(results_collinear.minimizers)

save_results(results_list_noncollinear, subfolder = "grasshopper_slabs_1_test_2_2", filename = "default");
save_results(results_list_collinear, subfolder = "grasshopper_slabs_1_test_2_2", filename = "default");

i = 45
fig = plot_forces(slab_results,:A,highlight=i,name="Experiment r$(row)c$(col)",override=true)
println(unique(slab_results.ids))

slab_results.Δ_local[2]
slab_results.x[i]

beam_elements = slab_base.model.elements[:beam]

slab_model = slab_base.model
beam_element = slab_model.elements[i]



"""
results collection for ROZVANY slabs
"""

begin
        
    slab_types = [:orth_biaxial, :orth_biaxial, :isotropic, :uniaxial, :uniaxial, :uniaxial, :uniaxial]
    vector_1ds = [[1.,0.], [1.,1.], [1.,0.], [1.,0.], [1.,1.], [0.,1.], [1.,-1.]]
    slab_types = [:isotropic]
    vector_1ds = [[1.,0.]]
    slab_sizers = [:uniform, :cellular]
    beam_sizers = [:discrete, :continuous]
    
    for beam_sizer in beam_sizers

        for slab_sizer in slab_sizers

            for i in 1:lastindex(slab_types)

                results_list_noncollinear = SlabOptimResults[]
                results_list_collinear = SlabOptimResults[]

                slab_type = slab_types[i]
                vector_1d = vector_1ds[i]

                load_ksi = (50 + 30) / (1e3 * 12^2) # live + dead, ksi
                load_kNm2 = load_ksi * 6895 # kN/m^2, typical slab load in residential buildings ~ 1.5, offices ~ 

                for idx in 1:14

                    println("\nSlab #$idx: $slab_type slab (vector: $vector_1d) with $slab_sizer thicknesses. Beams are $beam_sizer.")
                    geometry = generate_rozvany(10.,index=idx);
                    slab = SlabAnalysisParams(geometry, slab_type, vector_1d=vector_1d, spacing=0.1, w=load_kNm2, plot_analysis=true,
                                    fix_param=true, slab_sizer=slab_sizer, beam_sizer=beam_sizer); # original load was 7e3 kN/m²
            
                    try
                        slab = analyze_slab(slab); 
                    catch e 
                        println("\nERROR!! (Slab span may be too large...)\n")
                        println(e)

                        results = SlabOptimResults(slab)
                        push!(results_list_noncollinear, results)
                        push!(results_list_collinear, results)

                        continue
                    end
            
                    # analyze
                    minimizers, minimums, ids = optimal_beamsizer(slab, deflection_limit=true, verbose=false, minimum=false);
        
                    # postprocess
                    println("\nNoncollinear")
                    results_noncollinear = postprocess_slab(slab, minimizers, minimums, ids, collinear=false);
                    push!(results_list_noncollinear, results_noncollinear)
                    print_forces(results_noncollinear)

                    println("\ncollinear")
                    results_collinear = postprocess_slab(slab, minimizers, minimums, ids, collinear=true);
                    push!(results_list_collinear, results_collinear)
                    print_forces(results_collinear)
                        
                end
            
                save_results(results_list_noncollinear, subfolder = "rozvany_3_isotropic_orthogonal", filename = "default")
                save_results(results_list_collinear, subfolder = "rozvany_3_isotropic_orthogonal", filename = "default")

            end

        end

    end

end


"""
results collection for MY slabs
    - grasshopper_slabs_21 ... has a maximum depth of 21"
    - grasshopper_slabs_40 ... has a maximum depth of 40"
    - grasshopper_slabs_parametric_grid ... uses the parametric grid, max depth of 40"
    - grasshopper_slabs_redone ... assembly depth
    - grasshopper_slabs_redone_uniaxial ... fixes uniaxial maximum slab depth to be 1/28 span
    - grasshopper_slabs_continuous ... ostensibly fixes continuous issues
"""

begin
        
    max_depths = [21,40]
    slab_types = [:orth_biaxial, :orth_biaxial, :isotropic, :uniaxial, :uniaxial, :uniaxial, :uniaxial]
    vector_1ds = [[1.,0.], [1.,1.], [1.,0.], [1.,0.], [1.,1.], [0.,1.], [1.,-1.]]
    slab_sizers = [:uniform, :cellular] # depths
    beam_sizers = [:discrete, :continuous] # catalogue vs not

    #slab_types = [:uniaxial, :uniaxial, :uniaxial, :uniaxial]
    #vector_1ds = [[1.,0.], [1.,1.], [0.,1.], [1.,-1.]]
    beam_sizers = [:continuous]

    folder = "geometry_jsons/"
    #folder = "parametric_jsons/star/"
    #folder = "parametric_jsons/grid/"
    
    for max_depth in max_depths

        for beam_sizer in beam_sizers

            for slab_sizer in slab_sizers

                for i in 1:lastindex(slab_types)

                    results_list_noncollinear = SlabOptimResults[]
                    results_list_collinear = SlabOptimResults[]
                    names = String[]

                    slab_type = slab_types[i]
                    vector_1d = vector_1ds[i]

                    load_ksi = (50 + 30) / (1e3 * 12^2) # live + dead, ksi
                    load_kNm2 = load_ksi * 6895 # kN/m^2, typical slab load in residential buildings ~ 1.5, offices ~ 

                    if "$(slab_type)_$(slab_sizer)_$(vector_1d)_$(beam_sizer)_false.csv" in readdir("results/grasshopper_slabs_$(max_depth)_continuous")
                        println("Analysis already performed.")
                        continue
                    end

                    for filename in readdir(folder)

                        split_result = [string(substring) for substring in split(string(filename[1:end-4]),".")]
                        slab_name = split_result[1]

                        if slab_name == ""
                            continue
                        end
                
                        push!(names, slab_name)

                        println("\nSlab $slab_name: $slab_type slab (vector: $vector_1d) with $slab_sizer thicknesses. Beams are $beam_sizer.")

                        geometry_dict = JSON.parse(JSON.parse(replace(read(folder * filename, String),"\\n"=>""), dicttype=Dict))
                        geometry = generate_from_json(geometry_dict,plot=true)

                        slab = SlabAnalysisParams(geometry, slab_type, vector_1d=vector_1d, spacing=0.1, w=load_kNm2, plot_analysis=false,
                                        fix_param=true, slab_sizer=slab_sizer, beam_sizer=beam_sizer); # original load was 7e3 kN/m²
                
                        # analysis
                        try
                            slab = analyze_slab(slab); 
                        catch e 
                            println("\nERROR!! (Slab span may be too large...)\n")
                            println(e)

                            results = SlabOptimResults(slab)
                            push!(results_list_noncollinear, results)
                            push!(results_list_collinear, results)

                            continue
                        end
                        
                        minimizers = Vector[]
                        minimums = Float64[]
                        ids = []

                        # size optimization
                        try
                            minimizers, minimums, ids = optimal_beamsizer(slab, max_depth=max_depth, deflection_limit=true, verbose=false, minimum=false);

                        catch e   
                            println("\nERROR!! (Overutilized)")
                            println(e)

                            results = SlabOptimResults(slab)
                            push!(results_list_noncollinear, results)
                            push!(results_list_collinear, results)

                            continue
                        end
            
                        # postprocess
                        println("\nNoncollinear")
                        results_noncollinear = postprocess_slab(slab, minimizers, minimums, ids, max_depth=max_depth, check_collinear=false);
                        push!(results_list_noncollinear, results_noncollinear)
                        print_forces(results_noncollinear)

                        println("\ncollinear")
                        results_collinear = postprocess_slab(slab, minimizers, minimums, ids, max_depth=max_depth, check_collinear=true);
                        push!(results_list_collinear, results_collinear)
                        print_forces(results_collinear)
                        
                    end
                
                    save_results(results_list_noncollinear, names = names, subfolder = "grasshopper_slabs_$(max_depth)_continuous", filename = "default")
                    save_results(results_list_collinear, names = names, subfolder = "grasshopper_slabs_$(max_depth)_continuous", filename = "default")

                end

            end

        end
        
    end

end

"""
results collection for MY slabs v2.0
    - grasshopper_slabs_25 ... has a maximum depth of 25"
    - grasshopper_slabs_40 ... has a maximum depth of 40"
    - grasshopper_slabs_parametric_grid ... uses the parametric grid, max depth of 40"
"""

begin
        
    max_depths = [25.,40.]
    slab_types = [:isotropic, :orth_biaxial, :orth_biaxial, :uniaxial, :uniaxial, :uniaxial, :uniaxial]
    vector_1ds = [[1.,0.], [1.,0.], [1.,1.], [1.,0.], [1.,1.], [0.,1.], [1.,-1.]]
    slab_sizers = [:uniform, :cellular] # depths

    folder = "geometry_jsons/"
    #folder = "parametric_jsons/star/"
    #folder = "parametric_jsons/grid/"
    #folder = "revised_jsons/"

    max_depths = [40.]
    """slab_types = [:isotropic]
    vector_1ds = [[1.,0.]]"""
    slab_sizers = [:uniform]
    
    for max_depth in max_depths

        destination_folder = "results/3_grasshopper_slabs_stifness"

        if !isdir(destination_folder)
            mkdir(destination_folder)
        end

        for slab_sizer in slab_sizers

            for i in 1:lastindex(slab_types)

                results_list = SlabOptimResults[]
                names = String[]

                slab_type = slab_types[i]
                vector_1d = vector_1ds[i]
0
                load_ksi = (50 + 30) / (1e3 * 12^2) # live + dead, ksi
                load_kNm2 = load_ksi * 6895 # kN/m^2, typical slab load in residential buildings ~ 1.5, offices ~ 

                if "$(slab_type)_$(slab_sizer)_$(vector_1d)_$(max_depth).csv" in readdir(destination_folder)
                    println("Analysis already performed.")
                    continue
                end

                for filename in readdir(folder)

                    split_result = [string(substring) for substring in split(string(filename[1:end-4]),".")]
                    slab_name = split_result[1]

                    if slab_name == ""
                        continue
                    end

                    println("\nSlab $slab_name: $slab_type slab (vector: $vector_1d) with $slab_sizer thicknesses.")

                    geometry_dict = JSON.parse(JSON.parse(replace(read(folder * filename, String),"\\n"=>""), dicttype=Dict))
                    geometry = generate_from_json(geometry_dict,plot=true)
                    slab = SlabAnalysisParams(geometry, slab_type, slab_name=slab_name, vector_1d=vector_1d, spacing=0.1, w=load_kNm2, plot_analysis=false,
                                    fix_param=false, slab_sizer=slab_sizer, beam_sizer=:discrete); # original load was 7e3 kN/m²
                    
                    results_noncollinear_discrete, results_collinear_discrete, results_noncollinear_continuous, results_collinear_continuous = iterate_discrete_continuous(slab, geometry_dict, max_depth=max_depth, deflection_limit=true, minimum=false, save=true)
                    
                    push!(results_list, results_collinear_discrete)
                    push!(results_list, results_noncollinear_discrete)
                    push!(results_list, results_noncollinear_continuous)
                    push!(results_list, results_collinear_continuous)

                end
            
                save_results(results_list, subfolder = destination_folder, filename = "default")

            end

        end
        
    end

end



for i in 1:lastindex(results_list)

    results = results_list[i]

    println("Slab #$i: $(results.self.slab_type) slab (vector: $(results.self.vector_1d)) with $(results.self.slab_sizer) thicknesses")
    
    if results.area == 0.
        println("Slab span too large.\n")
    else
        println("Steel normalized mass: $(round(results.norm_mass_beams,digits=2)) kg/m²")
        println("Total normalized mass: $(round(results.norm_mass_beams + results.norm_mass_slab + results.norm_mass_rebar,digits=2)) kg/m²\n")
    end

end

"""
TODOS
NOTE
[ ] check for collinear elements
    - ensure they have the same section
    - optimize only over oNE of them (modify the broadcast function), including deflection limit
    - ensure they are moment connected
[ ] optimize over xy positions of elements
[ ] write a function that gets the tributary loads of a single element

TESTS
[x] use the eight examples, normalize by floor area, find total volume of material
[ ] model 10x5 rect in Karamba and test the same design
    - mesh load/line loads

QUESTIONS
[ ] how much does topology affect total mass in floors/grillages
[ ] chart structural weight by twist angle of rotated rectangle
"""