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

function plot_slab(self::SlabAnalysisParams, results::DataFrameRow=DataFrameRow())

    # Analyze the slab if it hasn't been analyzed yet
    if !self.plot_context.plot || isempty(self.areas)
        self.plot_context.plot = true
        self = analyze_slab(self)
    end

    model = self.model
    old_fig = self.plot_context.fig
    old_ax = self.plot_context.ax

    # Make a new figure and copy the axis
    new_fig = Figure()
    new_ax = Axis(new_fig[1,1])

    new_ax = copy_axis(old_ax, new_ax, alpha=0.5, scatter=false, beams=false)
    
    # Copy relevant axis properties
    elements = self.model.elements[:beam]
    sections = parse_sections(results.sections)
    areas = [W_imperial(section).A for section in sections]

    area_range = (minimum(areas), maximum(areas))

    for (i, element) in enumerate(elements)
        x = [element.nodeStart.position[1], element.nodeEnd.position[1]]
        y = [element.nodeStart.position[2], element.nodeEnd.position[2]]
        linewidth = sqrt(areas[i])
        lines!(new_ax, x, y, linewidth=linewidth, color=areas[i], colorrange=area_range, colormap=Reverse(:greys))

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
        
        # Add rotated text label at midpoint
        text!(new_ax, mid_x, mid_y, text=sections[i], 
              rotation=rotation,
              align=(:center, :center),
              fontsize=8)
    end

    display(new_fig)

end

