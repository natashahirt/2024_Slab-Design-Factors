function plot_8_stats_summary(df_all)

    GLMakie.activate!()

    df_all = filter(row -> !isnan(row.total_ec), df_all)

    filter_slab_sizer = row -> row.slab_sizer == "cellular"
    filter_beam_sizer = row -> row.beam_sizer == "continuous"
    filter_collinearity = row -> row.collinear == false
    filter_max_depth = row -> row.max_depth == 40
    filter_slab_type = row -> row.slab_type == "uniaxial"
    filter_type_and_vector = row -> row.slab_type == "uniaxial" && row.vector_1d_x == 1 && row.vector_1d_y == -1
    filter_category = row -> row.category == "nova"

    filter_conventional = row -> row.slab_type == "uniaxial" && row.vector_1d_x == 1 && row.vector_1d_y == 0 && row.beam_sizer == "discrete" && row.slab_sizer == "uniform" && row.collinear == true && row.max_depth == 40
    filter_bau = row -> row.name == "r1c2" && row.slab_type == "uniaxial" && row.slab_sizer == "uniform" && row.beam_sizer == "discrete" && row.collinear == true && row.vector_1d_x == 1 && row.vector_1d_y == 0 && row.max_depth == 40
    df_below_bau = filter(row -> row.total_ec < filter(filter_bau,df_all).total_ec[1], df_all)
    
    df_filtered = filter(filter_bau, df_all)

    round(mean(df_filtered.steel_ec), digits=2)
    round(mean(df_filtered.slab_ec), digits=2)
    round(mean(df_filtered.total_ec), digits=2)
    round(std(df_filtered.steel_ec), digits=2)
    round(std(df_filtered.slab_ec), digits=2)
    round(std(df_filtered.total_ec), digits=2)

    round(mean(df_below_bau.steel_ec), digits=2)
    round(mean(df_below_bau.slab_ec), digits=2)
    round(mean(df_below_bau.total_ec), digits=2)
    round(std(df_below_bau.steel_ec), digits=2)
    round(std(df_below_bau.slab_ec), digits=2)
    round(std(df_below_bau.total_ec), digits=2)


    bau = filter(filter_bau,df_all).total_ec[1] # business as usual
    reduction_conventional = (bau - minimum(filter(filter_conventional, df_all).total_ec)) / bau # reduction for conventional
    reduction_all = (bau - minimum(df_all.total_ec)) / bau # reduction for all 

    ###### ============================================================

    fontsize = 11

    fig = Figure(size=(190*4,190*2))
    master_grid = GridLayout(fig[1,1])
    grids = [GridLayout(master_grid[1,1]), GridLayout(master_grid[1,2])]
    colsize!(master_grid,1,Relative(1/2))
    texts = ["a) Full dataset", "b) Total EC < business-as-usual"]

    for (k, df_plot) in enumerate([df_all, df_below_bau])

        grid = grids[k]
        Label(grid[0, :], text = texts[k], fontsize = fontsize, font = :bold, tellwidth = false)

        ax1 = Axis(grid[1,1], title = "Total", ylabel = "EC [kgCO2e/m²]", xticks = (1:5, ["Slab sizing", "Beam\nsizing", "Beam\ncollinearity", "Assembly\ndepth", "Slab types"]), limits = (nothing,nothing,0,150), titlesize = fontsize, yticklabelsize = fontsize, xticklabelsize = fontsize, xlabelsize = fontsize, ylabelsize = fontsize)
        ax2 = Axis(grid[2,1], title = "Steel", ylabel = "EC [kgCO2e/m²]", xticks = (1:5, ["Slab sizing", "Beam\nsizing", "Beam\ncollinearity", "Assembly\ndepth", "Slab types"]), limits = (nothing,nothing,0,150), titlesize = fontsize, yticklabelsize = fontsize, xticklabelsize = fontsize, xlabelsize = fontsize, ylabelsize = fontsize)
        ax3 = Axis(grid[3,1], title = "Slab", ylabel = "EC [kgCO2e/m²]", xticks = (1:5, ["Slab sizing", "Beam\nsizing", "Beam\ncollinearity", "Assembly\ndepth", "Slab types"]), limits = (nothing,nothing,0,150), titlesize = fontsize, yticklabelsize = fontsize, xticklabelsize = fontsize, xlabelsize = fontsize, ylabelsize = fontsize)

        dodge_slab_sizer = [df_plot[i,:].slab_sizer == "uniform" ? 1 : 2 for i in 1:lastindex(df_plot.name)]
        dodge_beam_sizer = [df_plot[i,:].beam_sizer == "discrete" ? 1 : 2 for i in 1:lastindex(df_plot.name)]
        dodge_collinear = [df_plot[i,:].collinear == true ? 1 : 2 for i in 1:lastindex(df_plot.name)]
        dodge_max_depth = [df_plot[i,:].max_depth == 25 ? 1 : 2 for i in 1:lastindex(df_plot.name)]
        dodge_slab_type = [df_plot[i,:].slab_type == "isotropic" ? 1 : df_plot[i,:].slab_type == "orth_biaxial" ? 2 : 3 for i in 1:lastindex(df_plot.name)]

        for (i,dodge) in enumerate([dodge_slab_sizer, dodge_beam_sizer, dodge_collinear, dodge_max_depth, dodge_slab_type])

            if length(unique(dodge)) == 2
                color_map = map(d -> d == 1 ? 色[:skyblue] : 色[:irispurple], dodge)
            else
                color_map = map(d -> d == 1 ? 色[:skyblue] : d == 2 ? 色[:irispurple] : 色[:magenta], dodge)
            end

            for (j,ax) in enumerate([ax1, ax2, ax3])
                data = [df_plot.total_ec, df_plot.steel_ec, df_plot.slab_ec][j]
                boxplot!(ax, ones(length(df_plot.name)) * i, data, dodge = dodge, color = color_map, mediancolor=:black, whiskerlinewidth=0.5, medianlinewidth=0.5, markersize = 2)
            end

        end

        linkyaxes!(ax1,ax2,ax3)

    end

    display(fig)

    GC.gc()

end