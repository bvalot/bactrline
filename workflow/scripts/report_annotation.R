# Generate log file
log <- file(snakemake@log[[1]], open="wt")
sink(log, type = "message")

# Plasmid tool used
plasmid_tool <- snakemake@params[["plasmid_tool"]]

# Species specified
species <- snakemake@params[["species"]]



### AMR ###


# List report file generate by AMRFinderPlus
file_list_amr <- snakemake@input[["amr_tsv"]]

# List report file generate by plasmid tools
file_list_platon <- snakemake@input[["platon_tsv"]]
file_list_plasclass <- snakemake@input[["plasclass_tsv"]]

# Initialisation of the list for the output report
all_reports_amr <- list()

# Loop on each file
for (file_name in file_list_amr) {
    data <- read.table(file_name, header = TRUE, sep = "\t", check.names = FALSE, quote = "")
    
    # Extracting the sample name from the file name
    sample_name <- sub("_AMR.tsv", "", basename(file_name))

    if (nrow(data) > 0) {
        # Extracting identity and coverage of amr
        data$idcovplas <- paste0(data$"% Identity to reference", "/", data$"% Coverage of reference")
    } else {
        data <- data.frame("Element symbol" = NA, "Element name" = NA, "Type" = NA, "Subtype" = NA,
        "Class" = NA, "Subclass" = NA, "Closest reference accession" = NA, "idcovplas" = NA, check.names = FALSE)
    }
    
    
    ### PLASMID ###
    
    # Define threshold variable
    min_length <- snakemake@params[["min_length"]]
    
    plas_thresh_platon <- snakemake@params[["plas_thresh_platon"]]
    chr_thresh_platon <- snakemake@params[["chr_thresh_platon"]]
    
    plas_thresh_palsclass <- snakemake@params[["plas_thresh_palsclass"]]
    chr_thresh_plasclass <- snakemake@params[["chr_thresh_plasclass"]]
    
    ## Platon
    if (plasmid_tool == "platon" | plasmid_tool == "platon,plasclass") {
        # Find the file corresponding to the AMR file
        platon_file <- grep(sample_name, file_list_platon, value = TRUE)
        data_platon <- read.table(platon_file, header = TRUE, sep = "\t", check.names = FALSE, comment.char = "", quote = "")
        
        # Filter contigs by length and assign them a class (chromosomal, plasmid, unknown or unanalyzed)
        data_platon$Platon <- ifelse(data_platon$Length >= min_length, ifelse(data_platon$RDS >= plas_thresh_platon, 'P', ifelse(data_platon$RDS < plas_thresh_platon & data_platon$RDS >= chr_thresh_platon, 'U', 'C')), NA)
    }
    
    ## Plasclass
    if (plasmid_tool == "plasclass" | plasmid_tool == "platon,plasclass") {
        # Find the file corresponding to the AMR file
        plasclass_file <- grep(sample_name, file_list_plasclass, value = TRUE)
        data_plasclass <- read.table(plasclass_file, sep = "\t")
        
        # Extract length of the contig name
        data_plasclass$Length <- as.integer(sapply(strsplit(data_plasclass$V1, "_"), `[`, 4))
        
        # Filter contigs by length and assign them a class (chromosomal, plasmid, unknown or unanalyzed)
        data_plasclass$Plasclass <- ifelse(data_plasclass$Length >= min_length, ifelse(data_plasclass$V2 >= plas_thresh_palsclass, 'P', ifelse(data_plasclass$V2 < plas_thresh_palsclass & data_plasclass$V2 >= chr_thresh_plasclass, 'U', 'C')), NA)
    }
    
    # Merge plasmid data with amr data and id/cov
    if (plasmid_tool == "platon") {
        data <- merge(data, data_platon[, c("ID", "Platon")], by.x = "Contig id", by.y = "ID", all.x = TRUE)
        data$idcovplas <- paste0(data$idcovplas, "/", data$Platon)
    } else if (plasmid_tool == "plasclass") {
        data <- merge(data, data_plasclass[, c("V1", "Plasclass")], by.x = "Contig id", by.y = "V1", all.x = TRUE)
        data$idcovplas <- paste0(data$idcovplas, "/", data$Plasclass)
    } else if (plasmid_tool == "platon,plasclass") {
        data <- merge(data, data_platon[, c("ID", "Platon")], by.x = "Contig id", by.y = "ID", all.x = TRUE)
        data <- merge(data, data_plasclass[, c("V1", "Plasclass")], by.x = "Contig id", by.y = "V1", all.x = TRUE)
        data$idcovplas <- paste0(data$idcovplas, "/", data$Platon, "/", data$Plasclass)
    }
    ######

    # Creation of the amr report
    amr_report <- data.frame("Element symbol" = data$"Element symbol", "Element name" = data$"Element name", "Type" = data$"Type", "Subtype" = data$"Subtype", "Class" = data$"Class", "Subclass" = data$"Subclass", "Reference accession" = data$"Closest reference accession", "id/cov/plasm" = data$"idcovplas", check.names = FALSE)
    
    # Add sample name
    amr_report$Sample <- sample_name
    
    # Add the report to the list of reports
    all_reports_amr <- append(all_reports_amr, list(amr_report))
}

# Merge all reports amr into a single table
final_data <- do.call(rbind, all_reports_amr)

# List of unique gene
gene_names <- unique(final_data$"Element symbol")
gene_names <- gene_names[!is.na(gene_names)]

# Creation of a new final table
final_report <- data.frame(Sample = unique(final_data$Sample))

# Add column with the name of gene
for (gene in gene_names) {
    final_report[[gene]] <- NA
}

# Add value for each sample
for (i in 1:nrow(final_data)) {
    sample_name <- final_data$Sample[i]
    gene_name <- final_data$"Element symbol"[i]
    id_cov_value <- final_data$"id/cov/plasm"[i]
    
    if (!is.na(gene_name)) {
        value <- final_report[final_report$Sample == sample_name, gene_name]
        if (is.na(value)) {
            final_report[final_report$Sample == sample_name, gene_name] <- id_cov_value
        } else {
            final_report[final_report$Sample == sample_name, gene_name] <- paste(value, id_cov_value, sep = " ; ")
        }
    }
}

# Order gene by type (AMR, Virulence, Stress) and subclass
gene_info <- unique(final_data[, c("Element symbol", "Type", "Subclass")])
gene_info <- gene_info[!is.na(gene_info$"Element symbol"), ]
gene_info <- gene_info[order(gene_info$Type, gene_info$Subclass, gene_info$"Element symbol"), ]

# Order column by gene name
ordered_genes <- gene_info$"Element symbol"
final_report_amr <- final_report[, c("Sample", ordered_genes)]



### PYMLST ###


# List report file generate by pyMLST
file_list_pymlst <- snakemake@input[["pymlst_file"]]

# Initialisation of the list for the output report
all_reports_pymlst <- list()

# Loop on each file
for (file_name in file_list_pymlst) {
    data <- read.table(file_name, header = TRUE, sep = "\t", check.names = FALSE)
    
    # Extracting the sample name from the file name
    sample_name <- sub("_MLST.tsv", "", basename(file_name))

    # Rename sample name
    data$Sample <- sample_name
    
    # Add the report to the list of reports
    all_reports_pymlst <- append(all_reports_pymlst, list(data))
}

# Merge all reports pymlst into a single table
final_report_pymlst <- do.call(rbind, all_reports_pymlst)



### TYPING ###


## Clermont typing

file_list_clermont <- snakemake@input[["clermont_tsv"]]
all_reports_clmt <- list()

if (species == "Escherichia coli") {
    for (file_name in file_list_clermont) {
        data <- read.table(file_name, header = TRUE, sep = "\t", quote = "")
        sample_name <- sub("_CLMT.tsv", "", basename(file_name))
        type <- if (nrow(data) > 0) {paste(data$Type, collapse = ", ")} else NA
        allele <- if (nrow(data) > 0) {paste(data$Allele)} else NA
        notes <- if (nrow(data) > 0) {paste(data$Notes)} else NA
        clmt_report <- data.frame(Sample = sample_name, "CLMT" = type, "Gene" = allele, "Notes" = notes)
        all_reports_clmt <- append(all_reports_clmt, list(clmt_report))
    }

    final_report_clmt <- do.call(rbind, all_reports_clmt)
}


## Fim typing

file_list_fim <- snakemake@input[["fim_tsv"]]
all_reports_fim <- list()

if (species == "Escherichia coli") {
    for (file_name in file_list_fim) {
        data <- read.table(file_name, header = TRUE, sep = "\t", quote = "")
        sample_name <- sub("_FIM.tsv", "", basename(file_name))
        type <- if (nrow(data) > 0) {paste(data$Type, collapse = ", ")} else NA
        allele <- if (nrow(data) > 0) {paste(data$Allele)} else NA
        notes <- if (nrow(data) > 0) {paste(data$Notes)} else NA
        fim_report <- data.frame(Sample = sample_name, "FIM" = type, "Allele" = allele, "Comments" = notes)
        all_reports_fim <- append(all_reports_fim, list(fim_report))
    }
    
    final_report_fim <- do.call(rbind, all_reports_fim)
}


## Spa typing

# List report file generate by spaTyper
file_list_spa <- snakemake@input[["spa_tsv"]]

# Initialisation of the list for the output report
all_reports_spa <- list()

if (species == "Staphylococcus aureus") {
    # Loop on each file
    for (file_name in file_list_spa) {
        data <- read.table(file_name, header = TRUE, sep = "\t", check.names = FALSE, quote = "")
        
        # Extracting the sample name from the file name
        sample_name <- sub("_SPA.tsv", "", basename(file_name))
        
        # Creation of the spa report
        type <- if (nrow(data) > 0) {paste(data$Type, collapse = ", ")} else NA
        allele <- if (nrow(data) > 0) {paste(data$Allele)} else NA
        notes <- if (nrow(data) > 0) {paste(data$Notes)} else NA
        spa_report <- data.frame(Sample = sample_name, "SPA" = type, "Repeats" = allele, "Notes" = notes)
        
        # Add the report to the list of reports
        all_reports_spa <- append(all_reports_spa, list(spa_report))
    }
    
    # Merge all reports spatyper into a single table
    final_report_spa <- do.call(rbind, all_reports_spa)
}



### FINAL REPORT ###


if (species == "Escherichia coli") {
    report_list <- list(final_report_pymlst, final_report_clmt, final_report_fim, final_report_amr)
    header1 <- c("", "MLST", rep("", ncol(final_report_pymlst) - 2), 
                    "Clermont Typing", rep("", ncol(final_report_clmt) - 2),
                    "Fim Typing", rep("", ncol(final_report_fim) - 2), 
                    "AMR", rep("", sum(gene_info$Type == "AMR") - 1))
} else if (species == "Staphylococcus aureus") {
    report_list <- list(final_report_pymlst, final_report_spa, final_report_amr)
    header1 <- c("", "MLST", rep("", ncol(final_report_pymlst) - 2), 
                    "Spa Typing", rep("", ncol(final_report_spa) - 2), 
                    "AMR", rep("", sum(gene_info$Type == "AMR") - 1))
} else {
    report_list <- list(final_report_pymlst, final_report_amr)
    header1 <- c("", "MLST", rep("", ncol(final_report_pymlst) - 2),
                    "AMR", rep("", sum(gene_info$Type == "AMR") - 1))
}

if (sum(gene_info$Type == "STRESS") > 0) {
    header1 <- c(header1, "Stress", rep("", sum(gene_info$Type == "STRESS") - 1))
}
if (sum(gene_info$Type == "VIRULENCE") > 0) {
    header1 <- c(header1, "Virulence", rep("", sum(gene_info$Type == "VIRULENCE") - 1))
}

# Merge all report into the final report
final_report <- Reduce(function(x, y) merge(x, y, by="Sample"), report_list)

# Add second header
header2 <- colnames(final_report)

# Write output file with header
output_file <- snakemake@output[[1]]

writeLines(paste(header1, collapse = "\t"), con = output_file)
write(paste(header2, collapse = "\t"), file = output_file, append=TRUE)
write.table(final_report, file = output_file, sep="\t", row.names=FALSE, quote=FALSE, append=TRUE, col.names=FALSE)



### GENE REPORT ###


gene_report <- unique(final_data[, c("Element symbol", "Element name", "Type", "Subtype", "Class", "Subclass", "Reference accession")])

# Replace NA by temporary NA
gene_report_na <- gene_report
gene_report_na[is.na(gene_report_na)] <- "NA_TEMP"

# Aggregate referecne accession
gene_report_agg <- aggregate(`Reference accession` ~ `Element symbol` + `Element name` + `Type` + `Subtype` + `Class` + `Subclass`, 
                             data = gene_report_na, 
                             FUN = function(x) paste(x, collapse = ", "))

# Convert temporary NA back to NA
gene_report_agg[gene_report_agg == "NA_TEMP"] <- NA

# Order by type
gene_report_ord <- gene_report_agg[order(gene_report_agg$"Type", gene_report_agg$"Subtype", gene_report_agg$"Element symbol", gene_report_agg$"Class", gene_report_agg$"Subclass"), ]
gene_report_ord <- gene_report_ord[!is.na(gene_report_ord$"Element symbol"), ]

output_gene <- snakemake@output[[2]]
write.table(gene_report_ord, file = output_gene, sep="\t", row.names=FALSE, quote=FALSE)
