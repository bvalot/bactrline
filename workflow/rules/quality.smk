### REPORT TABLE ###

rule all_quality:
    input:
        "results/report/quality_report.tsv"

rule quality:
    input:
        kraken_report = expand("data/intermediate/kraken/{sample}/{sample}_report_length.tsv", sample=samples.index),
        quast_report = expand("data/intermediate/quast/{sample}/transposed_report.tsv", sample=samples.index),
        checkm_report = expand("data/intermediate/checkm2/{sample}/quality_report.tsv", sample=samples.index)
    output:
        quality_report = "results/report/quality_report.tsv"
    conda:
        "../envs/R.yml"
    log:
        "logs/quality/quality.log"
    params:
        tech_type = samples["type"].to_dict(),
        min_percent = config['quality']['min_percent'],
        genome_size = config['configuration']['genome_size'],
        warning_contamination = config['quality']['warning_contamination'],
        error_contamination = config['quality']['error_contamination'],
        warning_nbr_contig = config['quality']['warning_nbr_contig'],
        error_nbr_contig = config['quality']['error_nbr_contig'],
        warning_length_percent = config['quality']['warning_length_percent'],
        error_length_percent = config['quality']['error_length_percent'],
        warning_gc_percent = config['quality']['warning_gc_percent'],
        error_gc_percent = config['quality']['error_gc_percent'],
        warning_genus_percent = config['quality']['warning_genus_percent'],
        error_genus_percent = config['quality']['error_genus_percent'],
        warning_species_percent = config['quality']['warning_species_percent'],
        error_species_percent = config['quality']['error_species_percent']
    script:
        "../scripts/report_quality.R"
