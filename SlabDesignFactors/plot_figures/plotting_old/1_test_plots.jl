include("_results.jl")

# LARGE TEST DATAFRAME COLLECTION
begin
    global df_master = DataFrame(name=String[],area=Float64[],steel_norm=Float64[],concrete_norm=Float64[],rebar_norm=Float64[],slab_type=String[],slab_sizer=String[],vector_1d_x=Float64[],vector_1d_y=Float64[],beam_sizer=String[],collinear=Bool[],symbol=Symbol[],rotation=Float64[], max_depth=Float64[])

    #folders = ["grasshopper_slabs_21_first half/", "grasshopper_slabs_21_second half/", "grasshopper_slabs_21_third half/", "grasshopper_slabs_21_missing/"]
    #folders = ["grasshopper_slabs_40_continuous/", "grasshopper_slabs_40_discrete/", "grasshopper_slabs_40_missing/"]
    #folders = ["grasshopper_slabs_parametric_star/"]
    folders = ["grasshopper_slabs_21_redone_uniaxial/", "grasshopper_slabs_40_redone_uniaxial/", "grasshopper_slabs_parametric_grid_21_redone_uniaxial/", "grasshopper_slabs_parametric_grid_40_redone_uniaxial/", "grasshopper_slabs_parametric_star_21_redone_uniaxial/", "grasshopper_slabs_parametric_star_40_redone_uniaxial/"]

    for folder in folders

        for filename in readdir(folder)

            split_result = [string(substring) for substring in split(string(filename[1:end-4]),"_")]

            if "orth" in split_result && "overlaid" in split_result
                split_result = split_result[3:end]
                insert!(split_result,1,"orth_biaxial")
            end

            vector_1d = parse.(Float64,split(split_result[3][2:end-1],","))

            df_slab = CSV.read(folder * filename, DataFrame)
            df_slab = cull.(df_slab)

            df_slab.slab_type .= split_result[1]
            df_slab.slab_sizer .= split_result[2]
            df_slab.vector_1d_x .= vector_1d[1]
            df_slab.vector_1d_y .= vector_1d[2]
            df_slab.beam_sizer .= split_result[4]
            df_slab.collinear .= parse(Bool,split_result[5])
            df_slab.symbol .= :circle
            df_slab.rotation .= 0.
            
            # plotting
            for i in 1:length(df_slab.area)

                row = df_slab[i,:]

                if row.slab_type == "isotropic"

                    row.symbol = :star8
                    row.rotation = 0.
                    row.vector_1d_x = row.vector_1d_y = 0.

                elseif row.slab_type == "orth_biaxial"

                    row.symbol = :cross
                    row.rotation = get_vector_1d_angle([row.vector_1d_x,row.vector_1d_y])

                elseif row.slab_type == "uniaxial"

                    row.symbol = :hline
                    row.rotation = get_vector_1d_angle([row.vector_1d_x,row.vector_1d_y])

                end

            end
            
            df_master = vcat(df_master, df_slab)

        end
    
    end

    #df_master.max_depth .= 21

    #CSV.write("results_compiled_first_draft/grasshopper_slabs_redone_uniaxial.csv", df_master)

    return df_master

end

# PLOT LARGE TEST DATAFRAME

# embodied carbon for concrete
begin
    # setting the data
    data_ec = df_master

    colour_column = data_ec.collinear
    colours = [色[:ibm_cornflower], 色[:ibm_cerise]]
    color_names = ["Noncollinear", "collinear"]
    color_title = "collinearity" 

    """colour_column = data_ec.beam_sizer .== "continuous"
    colours = [色[:ibm_cornflower], 色[:ibm_cerise]]
    color_names = ["Discrete (W)", "Continuous"]
    color_title = "Beam Sizer" """

    """colour_column = data_ec.slab_sizer .== "uniform"
    colours = [色[:ibm_cornflower], 色[:ibm_cerise]]
    color_names = ["Cellular", "Uniform"]
    color_title = "Slab Sizer"
    """

    fig = Figure();
    ax = Axis(fig[1,1], xlabel = "EC steel kgCO2e/m²", ylabel = "EC concrete kgCO2e/m²", title="collinear vs. Noncollinear Elements", aspect = DataAspect(), limits=(0,nothing,0,nothing));

    # dots
    scatterplot = scatter!(ax, data_ec.steel_norm * ECC_STEEL, data_ec.concrete_norm * ECC_CONCRETE, marker=data_ec.symbol, rotations=(data_ec.rotation), color=colour_column, colorrange=(0,1), colormap = colours, inspector_label = (self, i, p) -> data_ec.name[i] * " (" * string(data_ec.vector_1d_x[i]) * ", " * string(data_ec.vector_1d_y[i]) * ")")

    # get the standard floor grillage
    df_standard = filter(row -> row.name == "r1c1" || row.name == "r1c2" || row.name == "r1c3", data_ec)
    scatter!(ax, df_standard.steel_norm * ECC_STEEL, df_standard.concrete_norm * ECC_CONCRETE, marker=df_standard.symbol, rotations=df_standard.rotation, color=:black, inspector_label = (self, i, p) -> df_standard.name[i] * " (" * string(df_standard.vector_1d_x[i]) * ", " * string(df_standard.vector_1d_y[i]) * ")")
    
    selected = nothing
    # select a unique floor grillage
    """selected = "r6c4"
    df_selected = filter(row -> row.name == selected, data_ec)
    scatter!(ax, df_selected.steel_norm * ECC_STEEL, df_selected.concrete_norm * ECC_CONCRETE, marker=df_selected.symbol, rotations=df_selected.rotation, color=色[:ibm_gold], inspector_label = (self, i, p) -> df_selected.name[i])
    """
    # legend
    elem_noncollinear = MarkerElement(color = colours[1], marker = :circle)
    elem_collinear = MarkerElement(color = colours[2], marker = :circle)
    elem_standard = MarkerElement(color = :black, marker = :circle)
    #elem_selected = MarkerElement(color = 色[:ibm_gold], marker =:circle)

    elem_isotropic = MarkerElement(color = :black, marker = :star8)
    elem_orth_biaxial = MarkerElement(color = :black, marker = :cross)
    elem_uniaxial = MarkerElement(color = :black, marker = :hline)

    if !isnothing(selected)
        Legend(fig[1,2],[[elem_noncollinear, elem_collinear], [elem_isotropic, elem_orth_biaxial, elem_uniaxial],[elem_standard,elem_selected]],[color_names,["Omnidirectional", "Orthogonal", "uniaxial"],["Business-as-usual (r1c1-3)", "Slab " * selected]], [color_title, "Slab type","Call-outs"], tellheight=false)
    else
        Legend(fig[1,2],[[elem_noncollinear, elem_collinear], [elem_isotropic, elem_orth_biaxial, elem_uniaxial],[elem_standard]],[color_names,["Omnidirectional", "Orthogonal", "uniaxial"],["Business-as-usual (r1c1-3)"]], [color_title, "Slab type","Call-outs"], tellheight=false)
    end

    di = DataInspector(fig)

    display(fig)
end

# embodied carbon for concrete and rebar
begin
    # setting the data
    data_ec = df_master

    """colour_column = data_ec.collinear
    colours = [色[:ibm_cornflower], 色[:ibm_cerise]]
    color_names = ["Noncollinear", "collinear"]
    color_title = "collinearity" """

    """colour_column = data_ec.beam_sizer .== "continuous"
    colours = [色[:ibm_cornflower], 色[:ibm_cerise]]
    color_names = ["Discrete (W)", "Continuous"]
    color_title = "Beam Sizer" """

    colour_column = data_ec.slab_sizer .== "uniform"
    colours = [色[:ibm_cornflower], 色[:ibm_cerise]]
    color_names = ["Cellular", "Uniform"]
    color_title = "Slab Sizer"

    fig = Figure();
    ax = Axis(fig[1,1], xlabel = "EC steel kgCO2e/m²", ylabel = "EC concrete + rebar kgCO2e/m²", title="Embodied carbon comparison", aspect = DataAspect(), limits=(0,nothing,0,nothing));

    # dots
    scatterplot = scatter!(ax, data_ec.steel_norm * ECC_STEEL, data_ec.concrete_norm * ECC_CONCRETE + data_ec.rebar_norm * ECC_REBAR, marker=data_ec.symbol, rotations=data_ec.rotation, color=colour_column, colorrange=(0,1), colormap = colours, inspector_label = (self, i, p) -> data_ec.name[i])

    # get the standard floor grillage
    df_standard = filter(row -> row.name == "r1c2", data_ec)
    scatter!(ax, df_standard.steel_norm * ECC_STEEL, df_standard.concrete_norm * ECC_CONCRETE + df_standard.rebar_norm * ECC_REBAR, marker=df_standard.symbol, rotations=df_standard.rotation, color=:black, inspector_label = (self, i, p) -> df_standard.name[i])
    
    # select a unique floor grillage
    selected = "r6c4"
    df_selected = filter(row -> row.name == selected, data_ec)
    scatter!(ax, df_selected.steel_norm * ECC_STEEL, df_selected.concrete_norm * ECC_CONCRETE + df_selected.rebar_norm * ECC_REBAR, marker=df_selected.symbol, rotations=df_selected.rotation, color=:red, inspector_label = (self, i, p) -> df_selected.name[i])

    # legend
    elem_noncollinear = MarkerElement(color = colours[1], marker = :circle)
    elem_collinear = MarkerElement(color = colours[2], marker = :circle)
    elem_standard = MarkerElement(color = :black, marker = :circle)
    elem_selected = MarkerElement(color =:red, marker =:circle)

    elem_isotropic = MarkerElement(color = :black, marker = :star8)
    elem_orth_biaxial = MarkerElement(color = :black, marker = :cross)
    elem_uniaxial = MarkerElement(color = :black, marker = :hline)

    Legend(fig[1,2],[[elem_noncollinear, elem_collinear], [elem_isotropic, elem_orth_biaxial, elem_uniaxial],[elem_standard,elem_selected]],[color_names,["Omnidirectional", "Orthogonal", "uniaxial"],["Business-as-usual (r1c2)", "Slab " * selected]], [color_title, "Slab type","Call-outs"], tellheight=false)
    
    di = DataInspector(fig)

    display(fig)
end

# bar chart
begin

    # filtering
    filter_function = row -> row.slab_sizer == "uniform"
    df_filtered = filter(filter_function, df_master)
 
    # setting the data
    data_ec = df_master 
    rebar_norm = copy(data_ec.rebar_norm)
    
    for i in 1:lastindex(data_ec.name)
        if data_ec.slab_type[i] == "orth_biaxial"
            rebar_norm[i] = rebar_norm[i] * 2
        end
    end

    total_ec = [data_ec[i,:].steel_norm * ECC_STEEL + data_ec[i,:].concrete_norm * ECC_CONCRETE + rebar_norm[i] * ECC_REBAR for i in 1:lastindex(data_ec.area)]
    data_ec.total_norm .= total_ec

    sort!(data_ec, [order(:total_norm)])

    labels = data_ec.name

    positions = 1:lastindex(data_ec.area)
    stack = repeat(positions,inner=3)
    categories = repeat(positions,outer=3)
    colours = repeat([1,2,3],inner=lastindex(data_ec.area))

    data_ec_steel = data_ec.steel_norm * ECC_STEEL
    data_ec_concrete = data_ec.concrete_norm * ECC_CONCRETE
    data_ec_rebar = rebar_norm * ECC_REBAR

    data_barplot = vcat(data_ec_concrete, data_ec_steel, data_ec_rebar)

    categories_standard = Int64[]
    data_standard = Float64[]
    for i in 1:lastindex(data_ec.area)
        row = data_ec[i,:]
        if row.name == "r1c2"
            push!(categories_standard, i)
            push!(data_standard, row.total_norm)
        end
    end

    fig = Figure();
    ax = Axis(fig[1,1], ylabel = "EC kgCO2e/m²", title="Embodied carbon comparison across Grasshopper slabs", aspect = DataAspect(), limits=(0,nothing,0,nothing));

    barplot!(ax, categories, data_barplot, stack=stack, gap = 0, color=colours, colormap = [:lightgrey, 色[:ibm_cornflower], 色[:ibm_cerise]])
    barplot!(ax, categories_standard, data_standard, color=:black)

    elem_concrete = MarkerElement(color = :lightgrey, marker = :circle)
    elem_steel = MarkerElement(color = 色[:ibm_cornflower], marker = :circle)
    elem_rebar = MarkerElement(color = 色[:ibm_cerise], marker = :circle)

    elem_standard = MarkerElement(color = :black, marker = :circle)

    Legend(fig[2,1], [[elem_rebar, elem_steel, elem_concrete],[elem_standard]],[["Rebar", "Steel", "Concrete"], ["Business as usual (r1c2)"]],["Materials", "Call-outs"], tellheight=false, tellwidth=false, orientation=:vertical, nbanks=3)

    fig

end

# BOTH 21" AND 40"
begin
    df_21 = CSV.read("results_compiled/grasshopper_slabs_max21.csv", DataFrame)
    df_40 = CSV.read("results_compiled/grasshopper_slabs_max40.csv", DataFrame)

    for df in [df_21, df_40]
        symbol_list = Symbol[]
        for symbol in df.symbol
            if symbol == "star8"
                push!(symbol_list,:star8)
            elseif symbol == "cross"
                push!(symbol_list,:cross)
            elseif symbol == "hline"
                push!(symbol_list,:hline)
            end
        end
        df.symbol = symbol_list

        rebar_norm = copy(df.rebar_norm)
    
        for i in 1:lastindex(df.name)
            row = df[i,:]
            if row.slab_type == "orth_biaxial"
                rebar_norm[i] = rebar_norm[i] * 2
            end
        end
    end

    df_all = vcat(df_21, df_40)
    
    fig = Figure();
    #ax = Axis3(fig[1,1], xlabel = "EC steel kgCO2e/m²", ylabel = "EC concrete kgCO2e/m²", zlabel = "EC rebar kgCO2e/m²", title="Embodied carbon comparison", limits=(0,nothing,0,nothing,0,nothing));
    ax = Axis(fig[1,1], xlabel = "EC steel kgCO2e/m²", ylabel = "EC concrete kgCO2e/m²", title="Embodied carbon comparison", aspect=DataAspect(), limits=(0,nothing,0,nothing));

    if typeof(ax) == Axis3

        df = df_21
        scatter!(ax, df.steel_norm * ECC_STEEL, df.concrete_norm * ECC_CONCRETE, rebar_norm * ECC_REBAR, marker=df.symbol, rotations=df.rotation, color=色[:ibm_cornflower], inspector_label = (self, i, p) -> df.name[i])
        df = df_40
        scatter!(ax, df.steel_norm * ECC_STEEL, df.concrete_norm * ECC_CONCRETE, rebar_norm * ECC_REBAR, marker=df.symbol, rotations=df.rotation, color=色[:ibm_cerise], inspector_label = (self, i, p) -> df.name[i])

    else

        df = df_21
        scatter!(ax, df.steel_norm * ECC_STEEL, df.concrete_norm * ECC_CONCRETE, marker=df.symbol, rotations=df.rotation, color=色[:ibm_cornflower], inspector_label = (self, i, p) -> df.name[i])
        df = df_40
        scatter!(ax, df.steel_norm * ECC_STEEL, df.concrete_norm * ECC_CONCRETE, marker=df.symbol, rotations=df.rotation, color=色[:ibm_cerise], inspector_label = (self, i, p) -> df.name[i])

    end

    elem_21 = MarkerElement(color = 色[:ibm_cornflower], marker = :circle)
    elem_40 = MarkerElement(color = 色[:ibm_cerise], marker = :circle)

    elem_isotropic = MarkerElement(color = :black, marker = :star8)
    elem_orth_biaxial = MarkerElement(color = :black, marker = :cross)
    elem_uniaxial = MarkerElement(color = :black, marker = :hline)

    display(fig) 
end

# plot the parametric slabs
begin
    df_star = CSV.read("results_compiled/grasshopper_slabs_parametric_star.csv", DataFrame)
    df_grid = CSV.read("results_compiled/grasshopper_slabs_parametric_grid.csv", DataFrame)

    #fig = Figure();
    ax = Axis(fig[1,1], xlabel = "EC steel kgCO2e/m²", ylabel = "EC concrete kgCO2e/m²", title="Embodied carbon comparison", aspect=DataAspect(), limits=(0,nothing,0,nothing));
    colors = [色[:ibm_cerise], 色[:ibm_cornflower]]

    for (i, df) in enumerate([df_star, df_grid])

        symbol_list = Symbol[]

        for symbol in df.symbol
            if symbol == "star8"
                push!(symbol_list,:star8)
            elseif symbol == "cross"
                push!(symbol_list,:cross)
            elseif symbol == "hline"
                push!(symbol_list,:hline)
            end
        end

        df.symbol = symbol_list

        scatter!(ax, df.steel_norm * ECC_STEEL, df.concrete_norm * ECC_CONCRETE, marker=df.symbol, rotations=df.rotation, color=colors[i], inspector_label = (self, i, p) -> df.name[i])

    end
    
    elem_isotropic = MarkerElement(color = :black, marker = :star8)
    elem_orth_biaxial = MarkerElement(color = :black, marker = :cross)
    elem_uniaxial = MarkerElement(color = :black, marker = :hline)

    Legend(fig[1,2],[[elem_isotropic,elem_orth_biaxial,elem_uniaxial]],[["Omnidirectional", "Orthogonal", "uniaxial"]],["Slab type"], tellheight=false)

    di = DataInspector(fig)

    display(fig) 
end

# plot the parametric slabs as a surface + heatmap
begin
    
    df = CSV.read("results_compiled/grasshopper_slabs_parametric_star.csv", DataFrame)

    filter_function = row -> row.slab_sizer == "uniform" && row.slab_type == "isotropic" && row.collinear == false
    df = filter(filter_function, df)
    println(df)

    symbol_list = Symbol[]
    x_list = Int64[]
    y_list = Int64[]
    steel_list = Float64[]
    concrete_list = Float64[]
    rebar_list = Float64[]
    total_EC_list = Float64[]
    label_list = String[]
    rotation_list = Float64[]

    rebar_norm = copy(df.rebar_norm)

    for i in 1:lastindex(df.name)
        row = df[i,:]
        range = findfirst("c",row.name) # c for star x for grid
        e_number = parse(Int,row.name[2:(range.start-1)])
        c_number = parse(Int,row.name[(range.stop+1):end])
        
        if (e_number == 10 && isodd(c_number)) || (c_number == 10 && isodd(e_number))
            continue
        end
        
        push!(x_list, e_number)
        push!(y_list, c_number)
        push!(steel_list, row.steel_norm * ECC_STEEL)
        push!(concrete_list, row.concrete_norm * ECC_STEEL)
        push!(rebar_list, row.rebar_norm * ECC_REBAR)
        push!(total_EC_list, steel_list[end] + concrete_list[end] + rebar_list[end])
        push!(label_list, row.name)
        push!(rotation_list, row.rotation)
    
        for i in 1:lastindex(df.name)
            if row.slab_type == "orth_biaxial"
                rebar_norm[i] = rebar_norm[i] * 2
            end
        end

        if row.symbol == "star8"
            push!(symbol_list,:star8)
        elseif row.symbol == "cross"
            push!(symbol_list,:cross)
        elseif row.symbol == "hline"
            push!(symbol_list,:hline)
        end
    end

    fig = Figure()
    ax = Axis3(fig[1,1], xlabel = "x", ylabel = "y", zlabel = "Embodied Carbon kgCO2e/m²", title = "Parametric grid", elevation=pi/2)
"""
    scatter!(ax, x_list, y_list, concrete_list, marker=symbol_list, rotations=rotation_list, color=:darkgrey, inspector_label = (self, i, p) -> label_list[i])
    surface!(ax, x_list, y_list, concrete_list, colormap=:greys, alpha = 0.2, transparency=true)

    scatter!(ax, x_list, y_list, steel_list, marker=symbol_list, rotations=rotation_list, color=色[:ibm_cornflower], inspector_label = (self, i, p) -> label_list[i])
    surface!(ax, x_list, y_list, steel_list, colormap=[:white, 色[:ibm_cornflower]], alpha = 0.2, transparency=true)

    scatter!(ax, x_list, y_list, rebar_list, marker=symbol_list, rotations=rotation_list, color=色[:ibm_cerise], inspector_label = (self, i, p) -> label_list[i])
    surface!(ax, x_list, y_list, rebar_list, colormap=:reds, alpha = 0.2, transparency=true)
"""
    levels = 50
    contour!(ax, x_list, y_list, concrete_list, color=:darkgrey, levels=levels)
    contour!(ax, x_list, y_list, steel_list, colormap=[:white,色[:ibm_cornflower]], levels=levels)
    contour!(ax, x_list, y_list, rebar_list, colormap=[:white,色[:ibm_cerise]], levels=levels)
    heatmap!(ax, x_list, y_list, total_EC_list, colormap=:greys)

    display(fig)

end


# plot all the pearametric slabs as a grid, showing the optimal orientation
begin
    
    df = CSV.read("results_compiled/grasshopper_slabs_parametric_star.csv", DataFrame)

    filter_function = row -> row.slab_sizer == "uniform" && row.collinear == false && row.beam_sizer == "discrete"
    df = filter(filter_function, df)

    symbol_list = Symbol[]
    x_list = Int64[]
    y_list = Int64[]

    for i in 1:lastindex(df.name)
        row = df[i,:]
        range = findfirst("c",row.name)
        push!(x_list, parse(Int,row.name[2:(range.start-1)]))
        push!(y_list, parse(Int,row.name[(range.stop+1):end]))

        if row.slab_type == "orth_biaxial"
            row.rebar_norm = row.rebar_norm * 2
        end

        if row.symbol == "star8"
            push!(symbol_list,:star8)
        elseif row.symbol == "cross"
            push!(symbol_list,:cross)
        elseif row.symbol == "hline"
            push!(symbol_list,:hline)
        end
    end

    df.x = x_list
    df.y = y_list
    df.symbol = symbol_list

    fig = Figure()
    ax = Axis3(fig[1,1], xlabel = "x", ylabel = "y", zlabel = "Embodied Carbon kgCO2e/m²", title = "Parametric grid")

    scatter!(ax, df.x, df.y, df.steel_norm * ECC_STEEL, marker=df.symbol, rotations=df.rotation, color=:lightblue, inspector_label = (self, i, p) -> df.name[i])
    surface!(ax, df.x, df.y, df.steel_norm * ECC_STEEL, colormap=:blues, alpha = 0.2)

    scatter!(ax, df.x, df.y, df.concrete_norm * ECC_CONCRETE, marker=df.symbol, rotations=df.rotation, color=:darkgrey, inspector_label = (self, i, p) -> df.name[i])
    surface!(ax, df.x, df.y, df.concrete_norm * ECC_CONCRETE, colormap=:greys, alpha=0.2)

    display(fig)

end