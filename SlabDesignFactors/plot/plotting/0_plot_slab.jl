# Get data from old figure's first plot
function copy_axis(old_ax::Axis, new_ax::Axis; alpha=1.0, scatter=true, lines=true, beams=true)
    if !isempty(old_ax.scene.plots)
        for plot in old_ax.scene.plots
            if isa(plot, Scatter) && scatter
                x_y_data = plot.args
                x, y = x_y_data[1][], x_y_data[2][]
                attributes = plot.attributes  # Get all attributes
                color = attributes[:color]
                strokecolor = attributes[:strokecolor]
                strokewidth = attributes[:strokewidth]
                marker = attributes[:marker]
                markersize = attributes[:markersize]
                if !isa(color[], Symbol)
                    colormap = attributes[:colormap]
                    colorrange = attributes[:colorrange]
                    scatter!(new_ax, x, y, color=color, colormap=colormap, colorrange=colorrange, marker=marker, markersize=markersize, strokecolor=strokecolor, strokewidth=strokewidth, alpha=alpha)
                else
                    scatter!(new_ax, x, y, color=color, marker=marker, markersize=markersize, strokecolor=strokecolor, strokewidth=strokewidth, alpha=alpha)
                end
            elseif isa(plot, Lines) && lines
                x_y_data = plot.args
                x, y = x_y_data[1][], x_y_data[2][]
                attributes = plot.attributes  # Get all attributes
                color = attributes[:color]
                if !isa(color[], Symbol)
                    colormap = attributes[:colormap]
                    colorrange = attributes[:colorrange]
                    lines!(new_ax, x, y, color=color, colormap=colormap, colorrange=colorrange, alpha=alpha)
                elseif beams == true
                    lines!(new_ax, x, y, color=color, alpha=alpha)
                end
            end
        end
    end

    return new_ax
end

function get_beams(old_ax::Axis)
    beams = []
    for plot in old_ax.scene.plots
        if isa(plot, Lines) && isa(plot.attributes[:color][], Symbol)
            push!(beams, plot)
        end
    end
    return beams
end

function parse_sections(sections_str::String)
    parsed_sections = Meta.parse(sections_str)
    parsed_array = eval(parsed_sections)
    return parsed_array
end

function parse_ids(ids_vector::Vector{SubString{String}})
    parsed_ids = Vector{Any}(undef, length(ids_vector))
    for (i, id) in enumerate(ids_vector)
        parsed_ids[i] = replace(replace(replace(id, r"[\[\]]" => ""), "\"" => ""), "Any" => "")
        parsed_ids[i] = strip(parsed_ids[i])
    end
    return string.(parsed_ids)
end

function plot_slab(self::SlabAnalysisParams, sections::Union{Vector{String}, Vector{Float64}})

    # Analyze the slab if it hasn't been analyzed yet
    if !self.plot_context.plot || isempty(self.areas) || isnothing(self.plot_context.ax)
        self.plot_context.plot = true
        self = analyze_slab(self)
    end

    model = self.model
    old_ax = self.plot_context.ax

    # Make a new figure and copy the axis
    new_fig = Figure(size=(600,400))
    new_ax = Axis(new_fig[1,1], aspect=DataAspect())
    old_ax = self.plot_context.ax

    new_ax = copy_axis(old_ax, new_ax, alpha=0.5, scatter=false, beams=false)
    hidespines!(new_ax)
    
    # Copy relevant axis properties
    elements = self.model.elements[:beam]
    if typeof(sections) <: Vector{String}
        areas = [W_imperial(section).A for section in sections]
    else
        areas = sections
        sections = string.(sections)
    end

    area_range = (0, sqrt(maximum(areas)))

    for (i, element) in enumerate(elements)
        x = [element.nodeStart.position[1], element.nodeEnd.position[1]]
        y = [element.nodeStart.position[2], element.nodeEnd.position[2]]
        linewidth = sqrt(areas[i])

        # Calculate clipped line coordinates by moving inward from endpoints
        # Get release type from element and determine DOFs
        release_type = typeof(element).parameters[1]

        start_dof = if release_type <: Union{Asap.FixedFixed, Asap.FixedFree}  && sum(element.nodeStart.dof[4:6]) == 0
            [0,0,0,0,0,0] # Fixed start
        else
            [0,0,0,1,1,1] # Free start
        end
        end_dof = if release_type <: Union{Asap.FixedFixed, Asap.FreeFixed}  && sum(element.nodeEnd.dof[4:6]) == 0
            [0,0,0,0,0,0] # Fixed end
        else
            [0,0,0,1,1,1] # Free end
        end

        # Default to no clipping for moment connections
        clip_start = sum(start_dof[4:6]) == 0 ? 0 : 0.3  # Clip if rotation DOF is fixed
        clip_end = sum(end_dof[4:6]) == 0 ? 0 : 0.3      # Clip if rotation DOF is fixed
        
        dx = x[2] - x[1]
        dy = y[2] - y[1]
        length = sqrt(dx^2 + dy^2)
        
        # Calculate parametric distances based on connection types
        t1 = clip_start/length
        t2 = (length-clip_end)/length
        
        x_clipped = [x[1] + t1*dx, x[1] + t2*dx]
        y_clipped = [y[1] + t1*dy, y[1] + t2*dy]
        lines!(new_ax, x_clipped, y_clipped, linewidth=linewidth, color=linewidth, colorrange=area_range, colormap=:BuPu)

        # Text
        # Calculate midpoint coordinates
        mid_x = (x[1] + x[2]) / 2
        mid_y = (y[1] + y[2]) / 2
        
        # Calculate rotation angle in radians
        rotation = let θ = atan((y[2] - y[1]), (x[2] - x[1]))
            if θ > π/2 || θ < -π/2
                θ + π 
            else
                θ
            end
        end
        
        # Add rotated text label at midpoint with white glow effect
        text!(new_ax, mid_x, mid_y, text=sections[i],
              rotation=rotation,
              align=(:center, :center),
              fontsize=8,
              color=:white,
              strokewidth=3,
              strokecolor=(:white, 0.8))
        # Add text on top without stroke for better visibility
        text!(new_ax, mid_x, mid_y, text=sections[i],
              rotation=rotation, 
              align=(:center, :center),
              fontsize=8,
              color=:black)
    end

    for node in model.nodes[:column]
        scatter!(new_ax, node.position[1], node.position[2], color=:deeppink, markersize=8, marker=:rect)
    end

    display(new_fig)

    GC.gc()

end

function plot_slab(self::SlabAnalysisParams, results::DataFrameRow=DataFrameRow())

    sections = parse_sections(results.sections)
    return plot_slab(self, sections)

end

function plot_slab(self::SlabAnalysisParams, beam_sizing_params::SlabSizingParams)
    
    slab_params = analyze_slab(self);
    slab_params, beam_sizing_params = optimal_beamsizer(slab_params, beam_sizing_params);
    slab_results = postprocess_slab(slab_params, beam_sizing_params, check_collinear=false);
    if occursin("W", slab_results.ids[1])
        sections = Vector{String}(slab_results.ids)
    else
        sections = parse.(Float64, slab_results.sections)
    end

    return plot_slab(slab_params, sections)

end