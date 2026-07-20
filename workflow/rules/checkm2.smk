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
    threads: config['quality']['checkm']['threads'] #config['resources']['threads']
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
