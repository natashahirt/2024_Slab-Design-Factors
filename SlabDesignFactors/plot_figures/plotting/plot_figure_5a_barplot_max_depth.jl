include("_results.jl")

begin
    
    df = csv_2_df(["3_grasshopper_slabs_topology/"], categories=["s"])
    df = filter(row -> row.beam_sizer == "discrete", df)
    
    df_names = DataFrame(name=String[], count=Int64[], percent = Float64[], depth=Float64[], mass=Float64[], max_depth=Int64[])

    for max_depth in [25, 40]

        W_names = String[]

        for i in 1:lastindex(df.name)
            if df[i,:].max_depth == max_depth
                ids = df[i,:].ids
                clean_str = strip(ids, ['[', ']'])
                elements = split(clean_str, ", ")
                elements = String.(strip.(elements, ['"']))
                append!(W_names, elements)
            end
        end

        dict_name_count = countmap(W_names)
        dict_name_mass = Dict(key => 0 for key in keys(dict_name_count))

        for W_name in keys(dict_name_count)
            split_name = split(W_name, r"(?<=\d)(?=\D)|(?<=\D)(?=\d)") # \d is decimal digit, \D is nondigit characters
            W_depth = parse(Int,split_name[2])
            W_mass = parse(Int,split_name[4])
            W_count = dict_name_count[W_name]
            W_percent = (W_count / length(W_names) .* 100) / 2
            push!(df_names, (W_name, W_count, W_percent, W_depth, W_mass, max_depth))
        end

        sort!(df_names, [:mass, :depth])
    
    end

    seen = String[]
    categories = Int64[]
    category_dict = Dict()

    for i in 1:lastindex(df_names.name)
        if df_names.name[i] in seen
            push!(categories, findfirst(x -> x == df_names.name[i], seen))
        else
            if isempty(categories)
                push!(categories, 1)
                push!(seen, df_names.name[i])
                category_dict[1] = df_names.name[i]
            else
                new_category = maximum(categories)+1
                push!(categories, new_category)
                push!(seen, df_names.name[i])
                category_dict[new_category] = df_names.name[i]
            end
        end
    end

    df_names.category .= categories
    fontsize = 11
    smallfontsize = 8

    fig = Figure(size=(190*4,190*2))
    CairoMakie.activate!()

    ax1 = Axis(fig[1,1], title = "b) Beam sizing by section", xticks = (unique(df_names.category), [category_dict[category] for category in unique(df_names.category)]), ylabel = "% of total sections", xticklabelrotation=pi/4, topspinevisible=false, rightspinevisible=false, yticklabelsize = fontsize, xticklabelsize = smallfontsize, xlabelsize = fontsize, ylabelsize = fontsize, titlesize=fontsize)
    ax2 = Axis(fig[1,1], xticks = (unique(df_names.category), [category_dict[category] for category in unique(df_names.category)]), ylabel = "", xticklabelrotation=pi/4, topspinevisible=false, rightspinevisible=false, yticklabelsize = fontsize, xticklabelsize = smallfontsize, xlabelsize = fontsize, ylabelsize = fontsize)    
    ax3 = Axis(fig[1,1], xticks = (unique(df_names.category), [category_dict[category] for category in unique(df_names.category)]), ylabel = "", xticklabelrotation=pi/4, topspinevisible=false, rightspinevisible=false, yticklabelsize = fontsize, xticklabelsize = smallfontsize, xlabelsize = fontsize, ylabelsize = fontsize)    
    
    hidedecorations!(ax2)
    hidedecorations!(ax3)

    max_depths = [25,40]
    colors = [色[:skyblue], 色[:magenta]]
    axes = [ax1, ax2]

    for i in 1:2
        max_depth = max_depths[i]
        color = colors[i]
        ax = axes[i]
        
        df_max_depth = filter(row -> row.max_depth == max_depth, df_names)
        barplot!(ax, df_max_depth.category, df_max_depth.percent, color = color, inspector_label = (self, j, p) -> df_max_depth.name[j], transparency=true)
    end

    df_max_depth = filter(row -> row.max_depth == 25, df_names)
    barplot!(ax3, df_max_depth.category, df_max_depth.percent, color = (色[:skyblue], 0.5), inspector_label = (self, j, p) -> df_max_depth.name[j], transparency=true)

    elem_25 = MarkerElement(color = (色[:skyblue]), marker = :rect)
    elem_40 = MarkerElement(color = (色[:magenta]), marker = :rect)

    axislegend(ax2, [elem_25, elem_40], ["25\"", "40\""], position = :rt, orientation = :vertical, labelhalign = :right, framevisible = true, backgroundcolor= :white, framecolor = :white, labelsize = fontsize)

    linkxaxes!(ax1, ax2, ax3)
    linkyaxes!(ax1, ax2, ax3)

    di = DataInspector(fig)

    display(fig)
    save("figures/sections barplot.pdf", fig)

end

