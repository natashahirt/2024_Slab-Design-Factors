function plot_6_histogram_beamsizer(df::DataFrame; category::String="topology")

    GLMakie.activate!()
    
    df = filter(row -> row.max_depth == 40, df)
    
    df_names = DataFrame(name=String[], area=Float64[], beam_sizer=String[])

    for beam_sizer in ["discrete", "continuous"]

        W_ids = String[]

        for i in 1:lastindex(df.name)
            if df[i,:].beam_sizer == beam_sizer
                ids = parse_ids(df[i,:].ids)
                append!(W_ids, ids)
            end
        end
        
        for W_id in W_ids
            if occursin("W", W_id)
                split_name = split(W_id, r"(?<=\d)(?=\D)|(?<=\D)(?=\d)") # \d is decimal digit, \D is nondigit characters
                W_depth = parse(Int,split_name[2])
                W_mass = parse(Int,split_name[4])
                W_area = W_imperial(W_id).A
                beam_sizer = "discrete"
            else
                W_area = parse(Float64,W_id)
                beam_sizer = "continuous"
            end
            push!(df_names, (W_id, W_area, beam_sizer))
        end
    
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
    
    fig = Figure(size=(190*4,190*1))
    grid = GridLayout(fig[1,1])
    Label(grid[0, 1:2], text = "a) Beam sizing by area", fontsize = fontsize, font = :bold)
    ax1 = Axis(grid[1,1], xticklabelrotation=pi/2, topspinevisible=false, rightspinevisible=false, xlabel="Area [inches²]", ylabel="% of sections", limits = (0,40,0,nothing), yticks = (0:0.1:1, [string(label) for label in collect(0:10:100)]), yticklabelsize = fontsize, xticklabelsize = fontsize, xlabelsize = fontsize, ylabelsize = fontsize)
    df_filtered = filter(row -> row.beam_sizer == "discrete", df_names)
    hist!(ax1, df_filtered.area, color = 色[:skyblue], normalization=:probability, bins=40)

    ax2 = Axis(grid[1,2], xticklabelrotation=pi/2, topspinevisible=false, rightspinevisible=false, xlabel="Area [inches²]", limits = (0,40,0,nothing), yticks = (0:0.1:1, [string(label) for label in collect(0:10:100)]), yticklabelsize = fontsize, xticklabelsize = fontsize, xlabelsize = fontsize, ylabelsize = fontsize)
    df_filtered = filter(row -> row.beam_sizer == "continuous", df_names)
    hist!(ax2, df_filtered.area, color = 色[:magenta], normalization=:probability, bins=40)

    elem_discrete = MarkerElement(color = 色[:skyblue], marker = :rect)
    elem_continuous = MarkerElement(color = 色[:magenta], marker = :rect)

    axislegend(ax2, [elem_discrete, elem_continuous], ["Discrete", "Continuous"], position = :rt, orientation = :vertical, labelhalign = :right, framevisible = true, backgroundcolor= :white, framecolor = :white,labelsize =fontsize)

    di = DataInspector(fig)

    linkxaxes!(ax1, ax2)
    linkyaxes!(ax1, ax2)

    display(fig)

end