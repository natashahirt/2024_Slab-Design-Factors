# LARGE TEST DATAFRAME COLLECTION
begin
    global df_master = DataFrame(area=Float64[],steel_norm=Float64[],concrete_norm=Float64[],rebar_norm=Float64[],slab_type=String[],slab_sizer=String[],vector_1d_x=Float64[],vector_1d_y=Float64[],beam_sizer=String[],collinear=Bool[],name=String[],symbol=Symbol[],rotation=Float64[])

    folder = "results/rozvany_2_fixed_param/"

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
        df_slab.name .= ""
        df_slab.symbol .= :circle
        df_slab.rotation .= 0.
        
        # plotting
        for i in 1:length(df_slab.area)

            row = df_slab[i,:]

            row.name = string(i)

            if row.slab_type == "isotropic"

                row.symbol = :star8
                row.rotation = 0.
                row.vector_1d_x = row.vector_1d_y = 0.

            elseif row.slab_type == "orth_biaxial"

                row.symbol = :cross
                row.rotation = get_vector_1d_angle([row.vector_1d_x,row.vector_1d_y])

            elseif row.slab_type == "uniaxial"

                row.symbol = :vline
                row.rotation = get_vector_1d_angle([row.vector_1d_x,row.vector_1d_y])

            end

        end
        
        df_master = vcat(df_master, df_slab)

    end

    return df_master

end

# PLOT LARGE TEST DATAFRAME
begin

    # filtering
    filter_function = row -> row.slab_sizer == "uniform"
    df_filtered = filter(filter_function, df_master)

    # setting the data
    data_ec = df_master

    """colour_column = data_ec.collinear
    colours = [:cadetblue2, :mediumorchid3]
    color_names = ["Noncollinear", "collinear"]
    color_title = "collinearity" """

    """colour_column = data_ec.beam_sizer .== "continuous"
    colours = [:cadetblue2, :mediumorchid3]
    color_names = ["Discrete (W)", "Continuous"]
    color_title = "Beam Sizer" """

    colour_column = data_ec.slab_sizer .== "uniform"
    colours = [:cadetblue2, :mediumorchid3]
    color_names = ["Cellular", "Uniform"]
    color_title = "Slab Sizer"

    # embodied carbon

    fig = Figure();
    ax = Axis(fig[1,1], xlabel = "EC steel kgCO2e/m²", ylabel = "EC concrete kgCO2e/m²", title="Embodied carbon comparison", aspect = DataAspect(), limits=(0,nothing,0,nothing));

    # lines
    for i in Set(data_ec.name)
        df_line = filter(row -> row.name == i, data_ec)
        sort!(df_line, [order(:concrete_norm)])
        color_param = parse(Int64,i)/(length(Set(data_ec.name)))
        lines!(ax, df_line.steel_norm * ECC_steel, df_line.concrete_norm * ECC_concrete, color=color_param, colormap=:dracula, colorrange=(0,1), alpha=0.5, linestyle=:dot)
    end

    # dots
    scatter!(ax, data_ec.steel_norm * ECC_steel, data_ec.concrete_norm * ECC_concrete, marker=data_ec.symbol, rotations=data_ec.rotation, color=colour_column, colorrange=(0,1), colormap = colours)

    # get the standard floor grillage
    df_standard = filter(row -> row.name == "10", data_ec)
    scatter!(ax, df_standard.steel_norm * ECC_steel, df_standard.concrete_norm * ECC_concrete, marker=df_standard.symbol, rotations=df_standard.rotation, color=:black, colormap = colours)

    # legend
    elem_noncollinear = MarkerElement(color = colours[1], marker = :circle)
    elem_collinear = MarkerElement(color = colours[2], marker = :circle)
    elem_standard = MarkerElement(color = :black, marker = :circle)

    elem_isotropic = MarkerElement(color = :black, marker = :star8)
    elem_orth_biaxial = MarkerElement(color = :black, marker = :cross)
    elem_uniaxial = MarkerElement(color = :black, marker = :vline)

    Legend(fig[1,2],[[elem_noncollinear, elem_collinear], [elem_isotropic, elem_orth_biaxial, elem_uniaxial],[elem_standard]],[color_names,["isotropic", "Orthogonal", "uniaxial"],["Business-as-usual"]], [color_title, "Slab type","Variety"], tellheight=false)

    fig
end

# BAR CHART
begin

    # filtering
    filter_function = row -> row.slab_sizer == "uniform"
    df_filtered = filter(filter_function, df_master)
 
    # setting the data
    data_ec = df_master
    total_ec = [data_ec[i,:].steel_norm * ECC_steel + data_ec[i,:].concrete_norm * ECC_concrete + data_ec[i,:].rebar_norm * ECC_rebar * 0.1 for i in 1:lastindex(data_ec.area)]
    data_ec.total_norm .= total_ec

    sort!(df_master, [order(:total_norm)])

    labels = data_ec.name

    positions = 1:lastindex(data_ec.area)
    stack = repeat(positions,inner=3)
    categories = repeat(positions,outer=3)
    colours = repeat([1,2,3],inner=lastindex(data_ec.area))

    data_ec_steel = data_ec.steel_norm * ECC_steel
    data_ec_concrete = data_ec.concrete_norm * ECC_concrete
    data_ec_rebar = data_ec.rebar_norm * ECC_rebar * 0.1

    data_barplot = vcat(data_ec_steel, data_ec_concrete, data_ec_rebar)

    fig = Figure();
    ax = Axis(fig[1,1], ylabel = "EC kgCO2e/m²", title="Embodied carbon comparison across Rozvany slabs", aspect = DataAspect(), limits=(0,nothing,0,nothing));

    barplot!(ax, categories, data_barplot, stack=stack, color=colours, colormap = [:steelblue3, :cadetblue2, :mediumorchid3])

    fig

end

# MAX SPAN DATAFRAME COLLECTION
begin 

    global df_max_span = DataFrame(area=Float64[],steel_norm=Float64[],concrete_norm=Float64[],rebar_norm=Float64[],slab_type=String[],slab_sizer=String[],vector_1d_x=Float64[],vector_1d_y=Float64[],beam_sizer=String[],collinear=Bool[],name=String[],symbol=Symbol[],rotation=Float64[],span_algorithm=String[])

    folder = "results/rozvany_3_max_span/"

    for subfolder in readdir(folder)

        span_algorithm = [string(substring) for substring in split(string(subfolder),"_")][2]
        
        for filename in readdir(folder * subfolder)

            split_result = [string(substring) for substring in split(string(filename[1:end-4]),"_")]

            vector_1d = parse.(Float64,split(split_result[3][2:end-1],","))

            df_slab = CSV.read(folder * subfolder *  "/" * filename, DataFrame)
            df_slab = cull.(df_slab)

            # all these are isotropic
            df_slab.slab_type .= split_result[1]
            df_slab.slab_sizer .= split_result[2]
            df_slab.vector_1d_x .= 0.
            df_slab.vector_1d_y .= 0.
            df_slab.beam_sizer .= split_result[4]
            df_slab.collinear .= parse(Bool,split_result[5])
            df_slab.name .= string.(collect(1:lastindex(df_slab.area)))
            df_slab.symbol .= :star8
            df_slab.rotation .= 0.
            df_slab.span_algorithm .= span_algorithm

            df_max_span = vcat(df_max_span, df_slab)

        end

    end

    return df_max_span

end

# PLOT MAX SPAN DATAFRAME
begin

    data_ec = df_max_span

    fig = Figure();
    ax = Axis(fig[1,1], xlabel = "EC steel kgCO2e/m²", ylabel = "EC concrete kgCO2e/m²", title="Embodied carbon comparison for different maximum span algorithms", aspect = DataAspect(), limits=(0,nothing,0,nothing));

    # dots
    algorithms = ["corner", "bisector", "orthogonal"]
    colors = [:pink, :cadetblue2, :mediumorchid3]

    for (i, algorithm) in enumerate(algorithms)
        filter_function = row -> row.span_algorithm == algorithm
        df_filtered = filter(filter_function, data_ec)
        scatter!(ax, df_filtered.steel_norm * ECC_steel, df_filtered.concrete_norm * ECC_concrete, marker=df_filtered.symbol, rotations=df_filtered.rotation, color=colors[i], label=algorithm)
    end

    Legend(fig[1,2],ax)

    fig

end