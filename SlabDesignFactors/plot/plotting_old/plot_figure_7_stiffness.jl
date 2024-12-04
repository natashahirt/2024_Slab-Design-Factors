include("_results.jl")

# SURFACE AND HEATMAP

begin
    
    df_param_fixed = csv_2_df(["3_grasshopper_slabs_topology/"], categories=["g"])
    df_param_unfixed = csv_2_df(["3_grasshopper_slabs_stiffness/"], categories=["s"])

    max_axis = 150

    fig = Figure(size=(190*3,190*3))
    ax = Axis(fig[1,1], aspect=1, xlabel = "Fixed tributaries EC kgCO2e/m²", ylabel = "Stiffness-adjusted tributaries EC kgCO2e/m²",limits=(0,max_axis,0,max_axis),titlesize = fontsize, yticklabelsize = fontsize, xticklabelsize = fontsize, xlabelsize = fontsize, ylabelsize = fontsize)

    slab_types = ["isotropic", "orth_biaxial", "orth_biaxial", "uniaxial", "uniaxial", "uniaxial", "uniaxial"]
    vector_1ds = [[0.,0.], [1.,0.], [1.,1.], [1.,0.], [0.,1.], [1.,1.], [1.,-1.]]
    colors = [色[:skyblue], 色[:irispurple], 色[:irispurple], 色[:magenta], 色[:magenta], 色[:magenta], 色[:magenta]]

    lines!(ax, [0,max_axis], [0,max_axis], color = :lightgrey, linestyle = :dash)
    lines!(ax, [0,max_axis], [0,max_axis*0.85], color = :grey90, linestyle = :dash)
    lines!(ax, [0,max_axis*0.85], [0,max_axis], color = :grey90, linestyle = :dash)

    for j in 1:lastindex(df_param_unfixed.name)

        unfixed_row = df_param_unfixed[j,:]
        
        filter_function = row -> row.slab_type == unfixed_row.slab_type && row.name == unfixed_row.name && row.slab_sizer == unfixed_row.slab_sizer && row.vector_1d_x == unfixed_row.vector_1d_x && row.vector_1d_y == unfixed_row.vector_1d_y && row.collinear == unfixed_row.collinear && row.beam_sizer == unfixed_row.beam_sizer && row.max_depth == unfixed_row.max_depth
        df_filtered = filter(filter_function, df_param_fixed)
        
        if length(df_filtered.name) == 0 
            continue
        end

        @assert length(df_filtered.name) == 1 "The actual length is $(length(df_filtered.name))"

        i = findfirst(==(unfixed_row.slab_type), slab_types)

        x_param_fixed = df_filtered.total_ec[1]
        y_param_unfixed = unfixed_row.total_ec

        marker = df_filtered.symbol[1]
        rotation = df_filtered.rotation[1]

        scatter!(ax,x_param_fixed,y_param_unfixed,marker=marker,rotation=rotation,color=colors[i],alpha=0.8,transparency=true,markersize=3)

    end

    elem_isotropic = MarkerElement(color = 色[:ceruleanblue], marker = :star8)
    elem_orthogonal = MarkerElement(color = 色[:irispurple], marker = :cross)
    elem_uniaxial = MarkerElement(color = 色[:magenta], marker = :hline)

    axislegend(ax, [elem_isotropic, elem_orthogonal, elem_uniaxial], ["Isotropic", "Biaxial Orthogonal", "Uniaxial"], position = :rb, orientation = :vertical, labelhalign = :right, framevisible = true, backgroundcolor= :white, framecolor = :white, labelsize=9, patchsize = (2,10), padding=(2,2,2,2))

    display(fig)
    save("figures/stiffness.pdf", fig)

end
