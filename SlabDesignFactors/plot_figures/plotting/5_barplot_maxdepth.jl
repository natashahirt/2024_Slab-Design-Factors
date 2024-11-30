"""
    plot_5_barplot_maxdepth(df::DataFrame; category=nothing)

Plots a bar chart showing the distribution of beam sizes by section for specified maximum depths.
If a category is provided, the data is filtered to include only that category.

# Arguments
- `df::DataFrame`: The input data frame containing beam information.
- `category`: An optional category to filter the data by.
"""
function plot_5_barplot_maxdepth(df::DataFrame; category=nothing)
    GLMakie.activate!()

    # Filter by category if provided
    if !isnothing(category)
        df = filter(row -> row.category == category, df)
    end

    # Filter for discrete beam sizes
    df = filter(row -> row.beam_sizer == "discrete", df)
    df_names = DataFrame(name=String[], count=Int64[], percent=Float64[], depth=Float64[], mass=Float64[], max_depth=Int64[])

    # Process for each max depth
    for max_depth in [25, 40]
        W_names = String[]

        # Collect names for the current max depth
        for row in eachrow(df)
            if row.max_depth == max_depth
                append!(W_names, parse_ids(row.ids))
            end
        end

        # Count occurrences and calculate mass
        dict_name_count = countmap(W_names)
        dict_name_mass = Dict(key => 0 for key in keys(dict_name_count))

        for W_name in keys(dict_name_count)
            split_name = split(W_name, r"(?<=\d)(?=\D)|(?<=\D)(?=\d)")
            W_depth = parse(Int, split_name[2])
            W_mass = parse(Int, split_name[4])
            W_count = dict_name_count[W_name]
            W_percent = (W_count / length(W_names) * 100) / 2
            push!(df_names, (W_name, W_count, W_percent, W_depth, W_mass, max_depth))
        end

        sort!(df_names, [:mass, :depth])
    end

    # Assign categories to names
    seen = String[]
    categories = Int64[]
    category_dict = Dict()

    for name in df_names.name
        if name in seen
            push!(categories, findfirst(x -> x == name, seen))
        else
            new_category = isempty(categories) ? 1 : maximum(categories) + 1
            push!(categories, new_category)
            push!(seen, name)
            category_dict[new_category] = name
        end
    end

    df_names.category .= categories

    # Plotting setup
    fontsize = 11
    smallfontsize = 8
    fig = Figure(size=(190*4, 190*2))

    # Create axes for the plots
    ax = Axis(fig[1, 1], 
        title="Beam sizing by section", 
        xticks=(unique(df_names.category), [category_dict[category] for category in unique(df_names.category)]), 
        ylabel="% of total sections", 
        xticklabelrotation=pi/2, 
        topspinevisible=false, 
        rightspinevisible=false, 
        yticklabelsize=fontsize, 
        xticklabelsize=smallfontsize, 
        xlabelsize=fontsize, 
        ylabelsize=fontsize, 
        titlesize=fontsize
    )

    # Plot grouped bar charts for each max depth
    max_depths = [25, 40]
    colors = [色[:skyblue], 色[:magenta]]

    for (i, max_depth) in enumerate(max_depths)
        color = colors[i]
        df_max_depth = filter(row -> row.max_depth == max_depth, df_names)
        barplot!(ax, df_max_depth.category .+ (i-1)*0.2, df_max_depth.percent, color=color, width=0.5, inspector_label=(self, j, p) -> df_max_depth.name[j], transparency=true)
    end

    # Legend setup
    elem_25 = MarkerElement(color=(色[:skyblue]), marker=:rect)
    elem_40 = MarkerElement(color=(色[:magenta]), marker=:rect)
    axislegend(ax, [elem_25, elem_40], ["25\"", "40\""], position=:rt, orientation=:vertical, labelhalign=:right, framevisible=true, backgroundcolor=:white, framecolor=:white, labelsize=fontsize)

    # Display the figure
    display(fig)
end

