rule all_quality:
    input:
        "workflow/reports/quality_report.tsv"


### KRAKEN ###

rule all_kraken: 
    input:
        expand("data/intermediate/kraken/{sample}_standard_output.txt", sample=samples.index),
        expand("data/intermediate/kraken/{sample}_report_length.tsv", sample=samples.index)


rule kraken:
    input:
        filtered_contig = "data/intermediate/filtered_contigs/{sample}.fasta",
        database_path = config['configuration']['kraken_db_path']
    output:
        kraken_output = "data/intermediate/kraken/{sample}_standard_output.txt"
    threads: config['resources']['threads']
    resources:
        mem_mb = config['resources']['mem_mb']
    log: "logs/kraken/{sample}.log"
    conda:
        "../envs/kraken.yml"
    params:
        extra_params = config['quality']['kraken']['extra_params']
    shell:
        """
        kraken2 --db {input.database_path} \
        --threads {threads} \
        --output {output.kraken_output} \
        {params.extra_params} \
        {input.filtered_contig} > {log} 2>&1
        """
        

rule kraken_count_length:
    input:
        kraken_output = "data/intermediate/kraken/{sample}_standard_output.txt",
    output:
        kraken_length = "data/intermediate/kraken/{sample}_report_length.tsv"
    log: "logs/kraken/{sample}_count_length.log"
    params:
        database_path = config['configuration']['kraken_db_path'],
        script_path = "workflow/scripts/make_kreport.py"
    shell:
        """
        python {params.script_path} -i {input.kraken_output} \
        -t {params.database_path}/ktaxonomy.tsv \
        -o {output.kraken_length} \
        --use-read-len > {log} 2>&1
        """


### QUAST ###

rule all_quast:
    input:
        expand("data/intermediate/quast/{sample}/transposed_report.tsv", sample=samples.index)


rule quast:
    input:
        filtered_contig = "data/intermediate/filtered_contigs/{sample}.fasta"
    output:
        quast_report = "data/intermediate/quast/{sample}/transposed_report.tsv"
    log: "logs/quast/{sample}.log"
    conda:
        "../envs/quast.yml"
    params:
        reference_file = config['configuration']['reference'],
        quast_directory = "data/intermediate/quast/{sample}/",
        extra_params = config['quality']['quast']['extra_params']
    shell:
        """
        quast {input.filtered_contig} \
        -o {params.quast_directory} \
        -r {params.reference_file} \
        {params.extra_params} > {log} 2>&1
        """


### CHECKM2 ###

rule all_checkm2:
    input:
        expand("data/intermediate/checkm2/{sample}/quality_report.tsv", sample=samples.index)
        

rule checkm2:
    input:
        filtered_contig = "data/intermediate/filtered_contigs/{sample}.fasta",
        database = config['configuration']['checkm2_db']
    output:
        checkm_log = "data/intermediate/checkm2/{sample}/quality_report.tsv"
    threads: config['resources']['threads']
    resources:
        mem_mb = config['resources']['mem_mb']
    log: "logs/checkm2/{sample}.log"
    conda:
        "../envs/checkm2.yml"
    params:
        output_directory = "data/intermediate/checkm2/{sample}/",
        extension = "fasta",
        extra_params = config['quality']['checkm']['extra_params']
    shell:
        """
        checkm2 predict -t {threads} \
        --input {input.filtered_contig} \
        --output-directory {params.output_directory} \
        --database_path {input.database} \
        --extension {params.extension} \
        --force \
        {params.extra_params} > {log} 2>&1
        """


### REPORT TABLE ###

rule quality:
    input:
        kraken_report = expand("data/intermediate/kraken/{sample}_report_length.tsv", sample=samples.index),
        quast_report = expand("data/intermediate/quast/{sample}/transposed_report.tsv", sample=samples.index),
        checkm_report = expand("data/intermediate/checkm2/{sample}/quality_report.tsv", sample=samples.index)
    output:
        quality_report = "results/quality_report.tsv"
    conda:
        "../envs/R.yml"
    log:
        "logs/quality/quality.log"
    params:
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
    
