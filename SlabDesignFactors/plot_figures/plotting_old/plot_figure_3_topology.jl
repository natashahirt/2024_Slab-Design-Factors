include("_results.jl")

begin
    # --------------------------------------------------------------------------------------
    # ** DATA **
    # --------------------------------------------------------------------------------------

    df = csv_2_df(["3_grasshopper_slabs_topology/"], categories=["t"])
    df.shorthand_best .= ""
    df.shorthand_worst .= ""

    max_steel = maximum(df.steel_ec) * 1.25
    max_slab = maximum(df.slab_ec) * 1.25
    
    slab_names = unique(df.name)
    df_best = similar(df,0)
    df_worst = similar(df,0)

    for name in slab_names
        df_name = filter(row -> row.name == name, df)
        best_row = eachrow(df_name)[findmin(df_name.total_ec)[2]]
        worst_row = eachrow(df_name)[findmax(df_name.total_ec)[2]]

        # best shorthand

        if best_row.slab_sizer == "uniform"
            best_row.shorthand_best *= "u"
        elseif best_row.slab_sizer == "cellular"
            best_row.shorthand_best *= "c"
        end

        if best_row.beam_sizer == "discrete"
            best_row.shorthand_best *= "W"
        elseif best_row.beam_sizer == "continuous"
            best_row.shorthand_best *= "c"
        end

        if best_row.collinear == false
            best_row.shorthand_best *= "n"
        elseif best_row.collinear == true
            best_row.shorthand_best *= "c"
        end

        best_row.shorthand_best *= string(Int(best_row.max_depth))

        # worst shorthand

        if worst_row.slab_sizer == "uniform"
            best_row.shorthand_worst *= "u"
        elseif worst_row.slab_sizer == "cellular"
            best_row.shorthand_worst *= "c"
        end

        if worst_row.beam_sizer == "discrete"
            best_row.shorthand_worst *= "W"
        elseif worst_row.beam_sizer == "continuous"
            best_row.shorthand_worst *= "c"
        end

        if worst_row.collinear == false
            best_row.shorthand_worst *= "n"
        elseif worst_row.collinear == true
            best_row.shorthand_worst *= "c"
        end

        best_row.shorthand_worst *= string(Int(worst_row.max_depth))

        push!(df_best, best_row)
        push!(df_worst, worst_row)
    end

    df_best.worst_total_ec .= df_worst.total_ec
    df_worst.best_total_ec .= df_best.total_ec

    # --------------------------------------------------------------------------------------
    # ** FIGURE **
    # --------------------------------------------------------------------------------------

    alpha = 0.8
    alpha_fade = 0.5
    transparency = true
    markersize = 5
    markersize_zoom = 7
    fontsize = 11
    smallfontsize = 5

    CairoMakie.activate!()
    fig = Figure(size=(190*4,190*2))
    ax1 = Axis(fig[1,1], ylabel = "EC kgCO2e/m²", xticklabelrotation=pi/2, limits=(0,length(df_best.name)+1,0,nothing), xticks=(1:lastindex(df_best.name),df_best.rowcol), yticklabelsize = fontsize, xticklabelsize = fontsize, xlabelsize = fontsize, ylabelsize = fontsize, titlesize = fontsize)
    
    # * BAR PLOT

    sort!(df_best, order(:total_ec))
    sort!(df_worst, order(:best_total_ec))
    println(df_worst)

    positions = 1:lastindex(df_best.area)
    stack = repeat(positions,inner=3)
    categories = repeat(positions,outer=3)
    colours = repeat([1,2,3],inner=lastindex(df_best.area))

    # do the grey
    hatchpattern = Makie.LinePattern(direction =[1,1]; width = 2, tilesize = (5,5), linecolor = :lightgrey, background_color = :white)
    barplot!(ax1, positions, df_best.worst_total_ec, color= hatchpattern, direction=:y, bar_labels = df_best.shorthand_worst, label_font = :italic, label_size = smallfontsize)

    df_concrete = df_best.concrete_ec
    df_steel = df_best.steel_ec
    df_rebar = df_best.rebar_ec

    data_barplot = vcat(df_concrete, df_steel, df_rebar)

    barplot!(ax1, positions, df_best.total_ec, color=:white, direction=:y, bar_labels = df_best.shorthand_best, label_font = :italic, label_size = smallfontsize)
    barplot!(ax1, categories, data_barplot, stack=stack, color=colours, direction=:y, colormap = [(色[:charcoalgrey]), (色[:skyblue]), (色[:magenta])], strokewidth=0.5)

    display(fig)
    save("figures/topology.pdf", fig)

end

println(df_worst)