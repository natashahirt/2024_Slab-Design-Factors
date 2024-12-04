include("_results.jl")

begin
    CairoMakie.activate!()
    fig = Figure(size=(190*4,190*4.6));

    # figure settings
    alpha = 0.2
    transparency = true
    markersize = 3.5
    markersizezoom = 5
    fontsize = 11
    smallfontsize = 8

    # legends
    elem_usual = MarkerElement(color = 色[:skyblue], marker = :circle)
    elem_optimal = MarkerElement(color = 色[:irispurple], marker = :circle)

    elem_isotropic = MarkerElement(color = 色[:skyblue], marker = :star8)
    elem_orthogonal = MarkerElement(color = 色[:irispurple], marker = :cross)
    elem_uniaxial = MarkerElement(color = 色[:magenta], marker = :hline)

    # grid
    grid = fig[1,1] = GridLayout()

    grid_multi = grid[1, 1] = GridLayout()
    grid_single = grid[2, 1] = GridLayout()

    colgap!(grid_multi, 2)
    rowgap!(grid_multi, 2)
    colgap!(grid, 2)
    rowgap!(grid, 2)

    # import CSVs
    df_all = csv_2_df(["results_files/3_grasshopper_slabs_topology/", "results_files/3_grasshopper_slabs_grid/", "results_files/3_grasshopper_slabs_nova_start/", "results_files/3_grasshopper_slabs_nova_end/"], categories=["t","g","s","s"])
    df_all = filter(row -> !isnan(row.total_ec), df_all)

    max_steel = maximum(df_all.steel_ec) * 1.25
    max_slab = maximum(df_all.slab_ec) * 1.25
    
    # first axis: cellular vs discrete slab_sizer
    ax1 = Axis(grid_multi[1,1], ylabel = "EC RC-slab kgCO2e/m²", title="a) Slab sizing", aspect = DataAspect(), limits=(0,max_steel,0,max_slab), yticklabelsize = fontsize, xticklabelsize = fontsize, xlabelsize = fontsize, ylabelsize = fontsize, titlesize = fontsize);
    
    filter_function = row -> row.slab_sizer == "uniform"
    df_usual = filter(filter_function, df_all)
    filter_function = row -> row.slab_sizer == "cellular"
    df_optimal = filter(filter_function, df_all)

    scatter!(ax1, df_usual.steel_ec, df_usual.slab_ec, marker=df_usual.symbol, rotation=df_usual.rotation, color=(色[:skyblue],alpha), transparency = transparency, markersize = markersize, inspector_label = (self, i, p) -> df_usual.category[i] * ": " * df_usual.name[i])
    scatter!(ax1, df_optimal.steel_ec, df_optimal.slab_ec, marker=df_optimal.symbol, rotation=df_optimal.rotation, color=(色[:irispurple],alpha), transparency = transparency, markersize = markersize, inspector_label = (self, i, p) -> df_optimal.category[i] * ": " * df_optimal.name[i])

    axislegend(ax1, [elem_usual, elem_optimal], ["Uniform", "Cellular"], position = :cb, orientation = :horizontal, labelhalign = :left, framevisible = true, backgroundcolor= :white, framecolor = :white, labelsize = smallfontsize, patchsize = (2,10), padding=(0,0,0,0))

    # second axis: continuous vs discrete beam_sizer
    ax2 = Axis(grid_multi[1,2], title="b) Beam sizing", aspect = DataAspect(), limits=(0,max_steel,0,max_slab), yticklabelsize = fontsize, xticklabelsize = fontsize, xlabelsize = fontsize, ylabelsize = fontsize, titlesize = fontsize);

    filter_function = row -> row.beam_sizer == "discrete"
    df_usual = filter(filter_function, df_all)
    filter_function = row -> row.beam_sizer == "continuous"
    df_optimal = filter(filter_function, df_all)

    scatter!(ax2, df_usual.steel_ec, df_usual.slab_ec, marker=df_usual.symbol, rotation=df_usual.rotation, color=(色[:skyblue],alpha), transparency = transparency, markersize = markersize, inspector_label = (self, i, p) -> df_usual.category[i] * ": " * df_usual.name[i])
    scatter!(ax2, df_optimal.steel_ec, df_optimal.slab_ec, marker=df_optimal.symbol, rotation=df_optimal.rotation, color=(色[:irispurple],alpha), transparency = transparency, markersize = markersize, inspector_label = (self, i, p) -> df_optimal.category[i] * ": " * df_optimal.name[i])

    axislegend(ax2, [elem_usual, elem_optimal], ["Catalog (W)", "Continuous"], position = :cb, orientation = :horizontal, labelhalign = :left, framevisible = true, backgroundcolor= :white, framecolor = :white, labelsize = smallfontsize, patchsize = (2,10), padding=(0,0,0,0))

    # third axis: collinear vs noncollinear elements
    ax3 = Axis(grid_multi[2,1], xlabel = "EC steel kgCO2e/m²", ylabel = "EC RC-slab kgCO2e/m²", title="c) Beam collinearity", aspect = DataAspect(), limits=(0,max_steel,0,max_slab), yticklabelsize = fontsize, xticklabelsize = fontsize, xlabelsize = fontsize, ylabelsize = fontsize, titlesize = fontsize);

    filter_function = row -> row.collinear == true
    df_usual = filter(filter_function, df_all)
    filter_function = row -> row.collinear == false
    df_optimal = filter(filter_function, df_all)

    scatter!(ax3, df_usual.steel_ec, df_usual.slab_ec, marker=df_usual.symbol, rotation=df_usual.rotation, color=(色[:skyblue],alpha), transparency = transparency, markersize = markersize, inspector_label = (self, i, p) -> df_usual.category[i] * ": " * df_usual.name[i])
    scatter!(ax3, df_optimal.steel_ec, df_optimal.slab_ec, marker=df_optimal.symbol, rotation=df_optimal.rotation, color=(色[:irispurple],alpha), transparency = transparency, markersize = markersize, inspector_label = (self, i, p) -> df_optimal.category[i] * ": " * df_optimal.name[i])

    axislegend(ax3, [elem_usual, elem_optimal], ["Collinear", "Noncollinear"], position = :cb, orientation = :horizontal, labelhalign = :left, framevisible = true, backgroundcolor= :white, framecolor = :white, labelsize = smallfontsize, patchsize = (2,10), padding=(0,0,0,0))

    # fourth axis: max height 25 vs 40
    ax4 = Axis(grid_multi[2,2], xlabel = "EC steel kgCO2e/m²", title="d) Assembly depth", aspect = DataAspect(), limits=(0,max_steel,0,max_slab), yticklabelsize = fontsize, xticklabelsize = fontsize, xlabelsize = fontsize, ylabelsize = fontsize, titlesize = fontsize);

    filter_function = row -> row.max_depth == 25
    df_usual = filter(filter_function, df_all)
    filter_function = row -> row.max_depth == 40
    df_optimal = filter(filter_function, df_all)

    scatter!(ax4, df_usual.steel_ec, df_usual.slab_ec, marker=df_usual.symbol, rotation=df_usual.rotation, color=(色[:skyblue],alpha), transparency = transparency, markersize = markersize, inspector_label = (self, i, p) -> df_usual.category[i] * ": " * df_usual.name[i])
    scatter!(ax4, df_optimal.steel_ec, df_optimal.slab_ec, marker=df_optimal.symbol, rotation=df_optimal.rotation, color=(色[:irispurple],alpha), transparency = transparency, markersize = markersize, inspector_label = (self, i, p) -> df_optimal.category[i] * ": " * df_optimal.name[i])

    axislegend(ax4, [elem_usual, elem_optimal], ["25\"", "40\""], position = :cb, orientation = :horizontal, labelhalign = :left, framevisible = true, backgroundcolor= :white, framecolor = :white, labelsize = smallfontsize, patchsize = (2,10), padding=(0,0,0,0))
    
    # fifth axis: different orientations
    ax5 = Axis(grid_single[1,1], aspect = DataAspect(), xlabel = "EC steel kgCO2e/m²", ylabel = "EC RC-slab kgCO2e/m²", title="e) Slab Types",limits=(0,max_steel,0,max_slab), yticklabelsize = fontsize, xticklabelsize = fontsize, xlabelsize = fontsize, ylabelsize = fontsize, titlesize = fontsize);

    filter_function = row -> row.slab_type == "isotropic"
    df_isotropic = filter(filter_function, df_all)
    filter_function = row -> row.slab_type == "orth_biaxial"
    df_orthogonal = filter(filter_function, df_all)
    filter_function = row -> row.slab_type == "uniaxial"
    df_uniaxial = filter(filter_function, df_all)

    scatter!(ax5, df_isotropic.steel_ec, df_isotropic.slab_ec, marker=df_isotropic.symbol, rotation=df_isotropic.rotation, color=(色[:skyblue],alpha), transparency = transparency, markersize = markersizezoom, inspector_label = (self, i, p) -> df_isotropic.category[i] * ": " * df_isotropic.name[i])
    scatter!(ax5, df_orthogonal.steel_ec, df_orthogonal.slab_ec, marker=df_orthogonal.symbol, rotation=df_orthogonal.rotation, color=(色[:irispurple],alpha), transparency = transparency, markersize = markersizezoom, inspector_label = (self, i, p) -> df_orthogonal.category[i] * ": " * df_orthogonal.name[i])
    scatter!(ax5, df_uniaxial.steel_ec, df_uniaxial.slab_ec, marker=df_uniaxial.symbol, rotation=df_uniaxial.rotation, color=(色[:magenta],alpha), transparency = transparency, markersize = markersizezoom, inspector_label = (self, i, p) -> df_uniaxial.category[i] * ": " * df_uniaxial.name[i])

    axislegend(ax5, [elem_isotropic, elem_orthogonal, elem_uniaxial], ["Isotropic", "Biaxial Orthogonal", "Uniaxial"], position = :cb, orientation = :horizontal, labelhalign = :left, framevisible = true, backgroundcolor= :white, framecolor = :white, labelsize = smallfontsize, patchsize = (2,10), padding=(0,0,0,0))

    # find the bau's

    filter_function = row -> row.name == "r1c2" && row.slab_type == "uniaxial" && row.slab_sizer == "uniform" && row.beam_sizer == "discrete" && row.collinear == true && row.vector_1d_x == 1 && row.vector_1d_y == 0 && row.max_depth == 40
    business_as_usual = filter(filter_function, df_all)

    bau_steel = business_as_usual.steel_ec
    bau_slab = business_as_usual.concrete_ec + business_as_usual.rebar_ec
    bau_total = bau_steel[1] + bau_slab[1]

    for ax in [ax1, ax2, ax3, ax4, ax5]
        vlines!(ax, bau_steel, color = :black, linestyle = :dash, transparency=true, linewidth=1)
        hlines!(ax, bau_slab, color = :black, linestyle = :dash, transparency=true, linewidth=1)
        lines!(ax, [bau_total, 0], [0, bau_total], color = :black, linestyle = :dash, transparency=true, linewidth=1)
    end

    # axis linking
    linkxaxes!(ax1, ax2, ax3, ax4, ax5)
    linkyaxes!(ax1, ax2, ax3, ax4, ax5)

    di = DataInspector(fig)

    display(fig) 
    save("figures/multiplot_aspect.pdf", fig)

end