include("../../scripts/_scripts.jl")
include("_plotting.jl")

df_all = assemble_data("SlabDesignFactors/results/remote_results/")

println("Mean slab embodied carbon m3: ", mean(df_all.slab_ec))
println("Mean slab embodied carbon kg: ", mean(df_all.slab_ec))

plot_1_multiplot(df_all)
plot_2_megaplot(df_all)

# Plot individual slabs

path = "SlabDesignFactors/jsons/topology/r1c2_copy.json"
name = basename(splitext(path)[1])    # Name for the plot
slab_filter = row -> row.name == name
df_slab = filter(slab_filter, df_all)
test_result = df_slab[2, :] # Get first row, can change index as needed

# Parse geometry from JSON
geometry_dict = JSON.parse(JSON.parse(replace(read(path, String), "\\n" => ""), dicttype=Dict))
geometry = generate_from_json(geometry_dict, plot=false, drawn=false);
println("length(geometry.elements[:beam]): ", length(geometry.elements[:beam]))
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

analysis = analyze_slab(slab_params);


for (i, element) in enumerate(slab_params.model.elements[:beam])
    println(i, ": ", element.length)
    if element.length > 10
        println(element.nodeStart.nodeID)
        println(element.nodeEnd.nodeID)
    end
end