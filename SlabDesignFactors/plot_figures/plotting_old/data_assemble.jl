function csv_2_df(folders::Vector{String}; categories::Vector{String}=[])

    if isempty(categories)
        categories = ["" for folder in folders]
    else
        @assert length(categories) == length(folders) "You need the same number of categories as folders"
    end

    df = DataFrame(category=String[], name=String[], area=Float64[], steel_norm=Float64[], concrete_norm=Float64[], rebar_norm=Float64[], max_depth=Float64[], slab_type=Symbol[], slab_sizer=Symbol[], beam_sizer=Symbol[], collinear=Bool[], symbol=Symbol[], rotation=Float64[], vector_1d_x=Float64[], vector_1d_y=Float64[], sections=Any[], ids=Any[])

    for (i,folder) in enumerate(folders)

        for filename in readdir(folder)

            df_slab = DataFrame(CSV.File(folder * filename))
            df_slab.symbol .= :circle
            df_slab.rotation .= 0.
            df_slab.category .= categories[i]

            df = vcat(df, df_slab)

        end
    
    end

    df.steel_ec = df.steel_norm .* ECC_STEEL
    df.concrete_ec = df.concrete_norm .* ECC_CONCRETE
    df.rebar_ec = df.rebar_norm .* ECC_REBAR
    df.slab_ec = df.concrete_ec + df.rebar_ec
    df.total_ec = df.steel_ec + df.concrete_ec + df.rebar_ec
    df.row .= 0
    df.col .= 0
    df.rowcol .= ""

    for i in 1:lastindex(df.name)

        row = df[i,:]

        if row.slab_type == "bidirectional"

            row.symbol = :star8
            row.rotation = 0.
            row.vector_1d_x = 0.
            row.vector_1d_y = 0.

        elseif row.slab_type == "orth_overlaid"

            row.symbol = :cross
            row.rotation = get_vector_1d_angle([row.vector_1d_x,row.vector_1d_y])

        elseif row.slab_type == "unidirectional"

            row.symbol = :hline
            row.rotation = get_vector_1d_angle([row.vector_1d_x,row.vector_1d_y])

        end

        split_name = split(row.name, r"(?<=\d)(?=\D)|(?<=\D)(?=\d)") # \d is decimal digit, \D is nondigit characters
        row.row = parse(Int,split_name[2])
        row.col = parse(Int,split_name[4])

        if contains(row.name, "e") && contains(row.name, "c")
            """if row.row == 1 && row.col == 1 # revised
                row.name = "e0c0"
                row.row = 10
                row.col = 0
            else
                row.row = row.row ./ 2 .+ 1
                row.col = row.col ./ 2 .+ 1
            end"""
            row.row = row.row
            row.col = row.col
        elseif contains(row.name, "x" )&& contains(row.name, "y")
            row.row += 1
            row.col += 1
        end

        row.rowcol = "$(row.category)[$(row.row),$(row.col)]"
        row.ids = split(row.ids, ",")

    end

    println("values: ",length(df.name))

    df = filter(row -> row.area != 0, df)
    sort!(df, [:row, :col])

    #CSV.write("2_grasshopper_slabs_second_draft/max_depth_25.csv", df)

    return df

end

function get_revised_star(folders::Vector{String}; categories::Vector{String}=[])

    df_revised = csv_2_df(["2_grasshopper_slabs_revised/"], categories=["s"])
    df_star = csv_2_df(folders, categories=categories)
    df_star_new = copy(df_star)

    for i in 1:lastindex(df_star.name)
        star_row = df_star[i,:]
        if star_row.row == 6
            filter_function = row -> row.slab_type == star_row.slab_type && row.vector_1d_x == star_row.vector_1d_x && row.vector_1d_y == star_row.vector_1d_y && row.collinear == star_row.collinear && row.beam_sizer == star_row.beam_sizer && row.slab_sizer == star_row.slab_sizer && row.max_depth == star_row.max_depth
            df_revised_filtered = filter(filter_function, df_revised)
            @assert length(df_revised_filtered.name) == 1
            df_revised_filtered.name .= star_row.name
            df_revised_filtered.row .= star_row.row
            df_revised_filtered.col .= star_row.col
            df_star_new[i,:] = df_revised_filtered[1,:]
        end
    end

    return df_star_new

end

function condense_nova(paths::Vector{String})

    for path in paths

    end

end