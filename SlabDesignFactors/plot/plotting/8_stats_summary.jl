"""
    create_slab_summary_table(df)

Creates a summary table comparing slabs with and without the "drawn" attribute.
The table includes mean values for steel, slab, and total EC for each slab name.
"""
function create_slab_summary_table(df)
    df = filter(row -> row.max_depth == 25, df)

    slab_names = ["triple_bay_bau", "triple_bay", "s6-6"]

    println("slab             standard                                   modified for release")
    println("             -------------------------                  ---------------------------")
    println("             steel ec    slab ec    total ec          steel ec    slab ec    total ec")
    println("             ---------   --------   ---------         ---------   --------   ---------")

    for slab_name in slab_names
        df_slab = filter(row -> row.name == slab_name, df)
        df_slab_drawn = filter(row -> row.name == slab_name * "_drawn" in df.name, df)
        
        # Get mean values for standard slab
        mean_steel_ec = mean(df_slab.steel_ec)
        mean_slab_ec = mean(df_slab.slab_ec) 
        mean_total_ec = mean(df_slab.total_ec)

        mean_steel_ec_drawn = mean(df_slab_drawn.steel_ec)
        mean_slab_ec_drawn = mean(df_slab_drawn.slab_ec)
        mean_total_ec_drawn = mean(df_slab_drawn.total_ec)

        # Print formatted row
        println(rpad(slab_name, 15) * lpad(round(mean_steel_ec, digits=1), 9) * "   " * lpad(round(mean_slab_ec, digits=1), 8) * "   " * lpad(round(mean_total_ec, digits=1), 9) * "         " * lpad(round(mean_steel_ec_drawn, digits=1), 9) * "   " * lpad(round(mean_slab_ec_drawn, digits=1), 8) * "   " * lpad(round(mean_total_ec_drawn, digits=1), 9))

    end
end

"""
df = assemble_data("SlabDesignFactors/results/test_results/constructability.csv")

# Get maximum and minimum total embodied carbon
max_ec = maximum(df_combined.steel_ec)
min_ec = minimum(df_combined.steel_ec)
# Get the row with minimum total embodied carbon
min_ec_row = df_combined[argmin(df_combined.steel_ec), :]

bau_slab.total_ec

# Calculate percentage improvement from BAU
pct_improvement = (bau_slab.steel_ec - min_ec) / bau_slab.total_ec * 100
println("\nPercentage improvement from BAU: ", round(pct_improvement, digits=1), "%")"""


"""
    create_filtered_summary_tables(df)

Creates separate summary tables for each design decision using filtering.
Each table includes mean and standard deviation for steel, slab, and total EC.
"""
function create_summary_tables(df)
    slab_filter = row -> row.name == "r1c2" && row.slab_type == "uniaxial" && row.beam_sizer == "discrete" && row.vector_1d_x == 1 && row.vector_1d_y == 0 && row.slab_sizer == "uniform" && row.max_depth == 40 && row.collinear == true && row.slab_min == true
    bau_slab = filter(slab_filter, df)[1,:]
    df = filter(row -> row.total_ec <= bau_slab.total_ec, df)

    # Define the design decisions, including slab types and vector combinations
    design_decisions = [:slab_sizer, :beam_sizer, :collinear, :slab_min, :slab_type, :max_depth, :category]

    for decision in design_decisions
        println("\n\nDesign Decision: ", decision)
        println("        Variation |             Mean / kgCO₂/m²     | Standard Dev / kgCO₂/m² | Slab count")
        println("                 |              -----  -----  ----- | -----  -----  -----  |  -----")

        # Get unique values for the current design decision
        unique_values = unique(df[!, decision])

        for value in unique_values
            # Filter the dataframe for the current design decision value
            df_filtered = filter(row -> row[decision] == value, df)

            # Calculate statistics
            mean_steel = mean(df_filtered.steel_ec)
            mean_slab = mean(df_filtered.slab_ec)
            mean_total = mean(df_filtered.total_ec)
            std_steel = std(df_filtered.steel_ec)
            std_slab = std(df_filtered.slab_ec)
            std_total = std(df_filtered.total_ec)
            slab_count = nrow(df_filtered)

            # Print the results with design decision in left cell
            println(rpad(string(decision) * ": " * string(value), 30) * 
                    lpad(round(mean_steel, digits=2), 6) * " " *
                    lpad(round(mean_slab, digits=2), 6) * " " *
                    lpad(round(mean_total, digits=2), 6) * " " *
                    lpad(round(std_steel, digits=2), 6) * " " *
                    lpad(round(std_slab, digits=2), 6) * " " *
                    lpad(round(std_total, digits=2), 6) * " " *
                    lpad(string(slab_count), 6))
        end
    end

    # Iterate over slab types and vector combinations
    slab_types = ["isotropic", "orth_biaxial", "orth_biaxial", "uniaxial", "uniaxial", "uniaxial", "uniaxial"]
    vector_combinations = [[0, 0], [1, 0], [1, 1], [1, 0], [0, 1], [1, 1], [1, -1]]

    println("\n\nDesign Decision: ", :slab_type)
    println("        Variation |             Mean / kgCO₂/m²     | Standard Dev / kgCO₂/m² | Slab count")
    println("                 |              -----  -----  ----- | -----  -----  -----  |  -----")

    
    for (slab_type, vector) in zip(slab_types, vector_combinations)

        df_filtered = filter(row -> row.slab_type == slab_type && 
                                          row.vector_1d_x == vector[1] && 
                                          row.vector_1d_y == vector[2], df)

         # Calculate statistics
         mean_steel = mean(df_filtered.steel_ec)
         mean_slab = mean(df_filtered.slab_ec)
         mean_total = mean(df_filtered.total_ec)
         std_steel = std(df_filtered.steel_ec)
         std_slab = std(df_filtered.slab_ec)
         std_total = std(df_filtered.total_ec)
         slab_count = nrow(df_filtered)

         # Print the results with design decision in left cell
         println(rpad(string(slab_type) * " | " * string(vector), 30) * 
                 lpad(round(mean_steel, digits=2), 6) * " " *
                 lpad(round(mean_slab, digits=2), 6) * " " *
                 lpad(round(mean_total, digits=2), 6) * " " *
                 lpad(round(std_steel, digits=2), 6) * " " *
                 lpad(round(std_slab, digits=2), 6) * " " *
                 lpad(round(std_total, digits=2), 6) * " " *
                 lpad(string(slab_count), 6))
    end

    # Print statistics for entire database
    println("\n\nEntire Database Statistics")
    println("        Variation |             Mean / kgCO₂/m²     | Standard Dev / kgCO₂/m² | Slab count")
    println("                 |              -----  -----  ----- | -----  -----  -----  |  -----")

    # Calculate statistics for full dataset
    mean_steel = mean(df.steel_ec)
    mean_slab = mean(df.slab_ec) 
    mean_total = mean(df.total_ec)
    std_steel = std(df.steel_ec)
    std_slab = std(df.slab_ec)
    std_total = std(df.total_ec)
    slab_count = nrow(df)

    # Print the results
    println(rpad("All designs", 30) * 
            lpad(round(mean_steel, digits=2), 6) * " " *
            lpad(round(mean_slab, digits=2), 6) * " " *
            lpad(round(mean_total, digits=2), 6) * " " *
            lpad(round(std_steel, digits=2), 6) * " " *
            lpad(round(std_slab, digits=2), 6) * " " *
            lpad(round(std_total, digits=2), 6) * " " *
            lpad(string(slab_count), 6))

    # Print statistics for BAU slab
    println("\n\nBusiness As Usual Slab Statistics")
    println("        Variation |             Mean / kgCO₂/m²     | Standard Dev / kgCO₂/m² | Slab count")
    println("                 |              -----  -----  ----- | -----  -----  -----  |  -----")

    # Print the results for single BAU slab
    println(rpad("BAU slab", 30) * 
            lpad(round(bau_slab.steel_ec, digits=2), 6) * " " *
            lpad(round(bau_slab.slab_ec, digits=2), 6) * " " *
            lpad(round(bau_slab.total_ec, digits=2), 6) * " " *
            lpad("0.00", 6) * " " *  # Standard deviation is 0 for single value
            lpad("0.00", 6) * " " *
            lpad("0.00", 6) * " " *
            lpad("1", 6))

end



# Example usage
# df = DataFrame(...) # Load your combined dataset here
# create_filtered_summary_tables(df)