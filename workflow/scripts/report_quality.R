# Generate log file
log <- file(snakemake@log[[1]], open="wt")
sink(log, type = "message")



### KRAKEN ###


# List all report files generate by KrakenTools
file_list_kraken <- snakemake@input[["kraken_report"]]

# Initialisation of the list for the output report
all_reports_kraken <- list()

# Loop on each file
for (file_name in file_list_kraken) {
    data <- read.table(file_name, header = FALSE, sep = "\t")
    colnames(data) <- c("value", "tot_length", "length", "rank", "taxid", "name")
	
    # Extracting the sample name from the file name
    sample_name <- sub("_report_length.tsv", "", basename(file_name))
	
    # Calculation of the sum of the total lengths and the percentage of each line
    sum_tot_length <- sum(data$length)
    data$percentage <- round((data$tot_length / sum_tot_length) * 100, 2)
	
    # Filtering data by percentage threshold
    data <- data[data$percentage >= snakemake@params[["min_percent"]], ]
	
    # Separation of data by rank (genus or species)
    genus <- data[data$rank == "G", ]
    species <- data[data$rank == "S", ]
	
    # Sort data in descending order value and cleaning spaces in names
    genus <- genus[order(-genus$value), ]
    genus$name <- sub("^\\s+", "", genus$name)
    species <- species[order(-species$value), ]
    species$name <- sub("^\\s+", "", species$name)
	
    # Assignment of better value for genus and species
    genus_major <- if (nrow(genus) > 0) {genus$name[1]} else NA
    species_major <- if (nrow(genus) > 0) {species$name[1]} else NA
	
    # Assignment of other genus and species and their percentage
    other_genus <- if (nrow(genus) > 1) {paste(genus$name[-1], " (", genus$percentage[-1], " %)", sep = "", collapse=", ")} else NA
    other_species <- if (nrow(species) > 1) {paste(species$name[-1], " (", species$percentage[-1], " %)", sep = "", collapse=", ")} else NA
	
    # Percentage of major genus and species
    genus_major_percent <- if (nrow(genus) > 0) {genus$percentage[1]} else NA
    species_major_percent <- if (nrow(genus) > 0) {species$percentage[1]} else NA
	
    # Creation of the quality report
    quality_report <- data.frame(
        Sample = sample_name,
        "Major Genus" = genus_major,
        "Major Genus (%)" = genus_major_percent,
        "Major Species" = species_major,
        "Major Species (%)" = species_major_percent,
        "Other Genus" = other_genus,
        "Other Species" = other_species,
        check.names = FALSE
    )
    
    # Add the report to the list of reports
    all_reports_kraken <- append(all_reports_kraken, list(quality_report))
}

# Merge all reports kraken into a single table
final_report_kraken <- do.call(rbind, all_reports_kraken)



### QUAST ###


# List report file generate by Quast
files_list_quast <- snakemake@input[["quast_report"]]

# Initialisation of the list for the output report
all_reports_quast <- list()

# Loop on each file
for (file in files_list_quast) {
    data_quast <- read.table(file, sep = "\t", quote = "", header = TRUE, comment.char = "", check.names = FALSE)
    
    # Extracting the sample name from the directory name
    path <- sub("/transposed_report.tsv", "", file)
    sample_name <- sub("data/intermediate/quast/", "", path)
    
    # Selection of columns to keep
    col_to_keep <- c("# contigs (>= 0 bp)", "Total length (>= 0 bp)", "Largest contig", "Reference length", "GC (%)", "Reference GC (%)", "N50", "L50")
    data_quast_filtered <- data_quast[, col_to_keep]
    
    # Rename column
    colnames(data_quast_filtered)[colnames(data_quast_filtered)=="# contigs (>= 0 bp)"] <- "Contigs"
    colnames(data_quast_filtered)[colnames(data_quast_filtered)=="Total length (>= 0 bp)"] <- "Total length"

    # Add column Sample
    data_quast_filtered$Sample <- sample_name

    # Add the report to the list of reports
    all_reports_quast <- append(all_reports_quast, list(data_quast_filtered))
}

# Merge all reports quast into a single table
final_report_quast <- do.call(rbind, all_reports_quast)



### CHECKM2 ###


# List report file generate by CheckM2
files_list_checkm <- snakemake@input[["checkm_report"]]

# Initialisation of the list for the output report
all_reports_checkm <- list()

# Loop on each file
for (file in files_list_checkm) {
    data_checkm <- read.table(file, sep = "\t", quote = "", header = TRUE, comment.char = "", check.names = FALSE)
    
    # Extracting the sample name from the directory name
    path <- sub("/quality_report.tsv", "", file)
    sample_name <- sub("data/intermediate/checkm2/", "", path)
    
    # Selection of columns to keep
    cols_to_keep <- c("Completeness", "Contamination")
    data_checkm_filtered <- data_checkm[, cols_to_keep]

    # Add column Sample
    data_checkm_filtered$Sample <- sample_name

    # Add the report to the list of reports
    all_reports_checkm <- append(all_reports_checkm, list(data_checkm_filtered))
}

# Merge all reports checkm into a single table
final_report_checkm <- do.call(rbind, all_reports_checkm)



### FINAL REPORT ###


report_list <- list(final_report_kraken, final_report_quast, final_report_checkm)

# Merge all report into the final report
final_report <- Reduce(function(x, y) merge(x, y, by="Sample"), report_list)

# Change the order of the final report
final_report <- final_report[,c("Sample", "Contigs", "Total length", "Largest contig", "GC (%)", "N50", "L50", "Major Genus", "Major Genus (%)", "Major Species", "Major Species (%)", "Other Genus", "Other Species", "Reference length", "Reference GC (%)", "Completeness", "Contamination")]

# Define threshold variable 
genome_size <- snakemake@params[["genome_size"]]

warning_contamination <- snakemake@params[["warning_contamination"]]
error_contamination <- snakemake@params[["error_contamination"]]

warning_contigs <- snakemake@params[["warning_nbr_contig"]]
error_contigs <- snakemake@params[["error_nbr_contig"]]

warning_length_pct <- snakemake@params[["warning_length_percent"]] / 100
error_length_pct <- snakemake@params[["error_length_percent"]] / 100

warning_gc_pct <- snakemake@params[["warning_gc_percent"]] / 100
error_gc_pct <- snakemake@params[["error_gc_percent"]] / 100

warning_genus_pct <- snakemake@params[["warning_genus_percent"]]
error_genus_pct <- snakemake@params[["error_genus_percent"]]

warning_species_pct <- snakemake@params[["warning_species_percent"]]
error_species_pct <- snakemake@params[["error_species_percent"]]

# Evaluation of contamination
final_report$"Quality validation" <- "PASS"

# Warning
final_report$"Quality validation"[
    (final_report$Contamination >= warning_contamination & final_report$Contamination < error_contamination) | 
    (final_report$Contigs >= warning_contigs & final_report$Contigs < error_contigs) | 
    (final_report$"Total length" >= genome_size *(1 + warning_length_pct) | final_report$"Total length" <= genome_size *(1 - warning_length_pct)) | 
    (final_report$"GC (%)" >= final_report$"Reference GC (%)" * (1 + warning_gc_pct) | final_report$"GC (%)" <= final_report$"Reference GC (%)" * (1 - warning_gc_pct)) |
    (final_report$"Major Genus (%)" > error_genus_pct & final_report$"Major Genus (%)" <= warning_genus_pct) | 
    (final_report$"Major Species (%)" > error_species_pct & final_report$"Major Species (%)" <= warning_species_pct)
] <- "WARNING"

# Error
final_report$"Quality validation"[
    (final_report$Contamination >= error_contamination) | 
    (final_report$Contigs >= error_contigs) | 
    (final_report$"Total length" >= genome_size *(1 + error_length_pct) | final_report$"Total length" <= genome_size *(1 - error_length_pct)) | 
    (final_report$"GC (%)" >= final_report$"Reference GC (%)" * (1 + error_gc_pct) | final_report$"GC (%)" <= final_report$"Reference GC (%)" * (1 - error_gc_pct)) |
    (final_report$"Major Genus (%)" <= error_genus_pct) | 
    (final_report$"Major Species (%)" <= error_species_pct)
] <- "ERROR"

# Add column with "Problematic parameters"
final_report$"Problematic parameters" <- ""

# Contamination
contamination <- final_report$Contamination >= warning_contamination
final_report$"Problematic parameters"[contamination] <- "Contamination"

# Contigs
contigs <- final_report$Contigs >= warning_contigs
final_report$"Problematic parameters"[contigs] <- paste(final_report$"Problematic parameters"[contigs], "Contigs", sep = ", ")

# Total length
length <- final_report$"Total length" >= genome_size * (1 + warning_length_pct) | final_report$"Total length" <= genome_size * (1 - warning_length_pct)
final_report$"Problematic parameters"[length] <- paste(final_report$"Problematic parameters"[length], "Total length", sep = ", ")

# GC (%)
gc <- final_report$"GC (%)" >= final_report$"Reference GC (%)" * (1 + warning_gc_pct) | final_report$"GC (%)" <= final_report$"Reference GC (%)" * (1 - warning_gc_pct)
final_report$"Problematic parameters"[gc] <- paste(final_report$"Problematic parameters"[gc], "GC (%)", sep = ", ")

# Major Genus (%)
genus <- final_report$"Major Genus (%)" < warning_genus_pct
final_report$"Problematic parameters"[genus] <- paste(final_report$"Problematic parameters"[genus], "Major Genus (%)", sep = ", " )

# Major Species (%)
species <- final_report$"Major Species (%)" < warning_species_pct
final_report$"Problematic parameters"[species] <- paste(final_report$"Problematic parameters"[species], "Major Species (%)", sep = ", " )

final_report$"Problematic parameters" <- sub("^, ", "", final_report$"Problematic parameters")

# Write the final report to file
write.table(final_report, file = snakemake@output[[1]], sep="\t", row.names=FALSE, quote=FALSE)

