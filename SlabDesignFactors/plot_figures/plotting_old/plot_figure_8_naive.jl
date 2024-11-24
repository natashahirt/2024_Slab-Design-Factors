include("_results.jl")

# SURFACE AND HEATMAP

begin
    
    df_regular = csv_2_df(["3_grasshopper_slabs_topology/"], categories=["g"])
    df_naive = csv_2_df(["3_grasshopper_slabs_naive/"], categories=["s"])

    max_axis = maximum(vcat(df_regular.total_ec, df_naive.total_ec)) + 20

    fig = Figure(size=(190*3,190*3))
    ax = Axis(fig[1,1], aspect=DataAspect(), xlabel = "Regular loading EC kgCO2e/m²", ylabel = "Naïve loading EC kgCO2e/m²",limits=(0,max_axis,0,max_axis))

    slab_types = ["isotropic", "orth_biaxial", "orth_biaxial", "uniaxial", "uniaxial", "uniaxial", "uniaxial"]
    vector_1ds = [[0.,0.], [1.,0.], [1.,1.], [1.,0.], [0.,1.], [1.,1.], [1.,-1.]]
    colors = [色[:skyblue], 色[:irispurple], 色[:irispurple], 色[:magenta], 色[:magenta], 色[:magenta], 色[:magenta]]

    for i in 1:lastindex(slab_types)

        slab_type = slab_types[i]
        vector_1d = vector_1ds[i]
        color = colors[i]

        for j in 1:lastindex(df_naive.name)

            naive_row = df_naive[j,:]
            
            filter_function = row -> row.slab_type == slab_type && row.name == naive_row.name && row.slab_sizer == naive_row.slab_sizer && row.vector_1d_x == vector_1d[1] && row.vector_1d_y == vector_1d[2] && row.collinear == naive_row.collinear && row.beam_sizer == naive_row.beam_sizer && row.max_depth == naive_row.max_depth
            df_filtered = filter(filter_function, df_regular)
            
            if length(df_filtered.name) == 0 
                continue
            end

            @assert length(df_filtered.name) == 1 "The actual length is $(length(df_filtered.name))"

            x_param_fixed = df_filtered.total_ec[1]
            y_param_unfixed = naive_row.total_ec

            marker = df_filtered.symbol[1]
            rotation = df_filtered.rotation[1]

            scatter!(ax,x_param_fixed,y_param_unfixed, marker=marker, rotation=rotation, color=colors[i], alpha=0.8,transparency=true,markersize=5)

        end

    end

    display(fig)

end
