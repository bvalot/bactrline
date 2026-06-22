### KRAKEN ###

rule all_kraken: 
    input:
        expand("data/intermediate/" + TECH + "/kraken/{sample}_standard_output.txt", sample=samples.index),
        expand("data/intermediate/" + TECH + "/kraken/{sample}_report_length.tsv", sample=samples.index),



rule kraken:
    input:
        filtered_contig = "data/intermediate/" + TECH + "/filtered_contigs/{sample}.fasta",
        database_path = config['configuration']['kraken_db_path']
    output:
        kraken_output = "data/intermediate/" + TECH + "/kraken/{sample}_standard_output.txt"
    threads: config['resources']['threads']
    resources:
        mem_mb = config['resources']['mem_mb']
    log: "logs/" + TECH + "/kraken/{sample}.log"
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
        kraken_output = "data/intermediate/" + TECH + "/kraken/{sample}_standard_output.txt",
    output:
        kraken_length = "data/intermediate/" + TECH + "/kraken/{sample}_report_length.tsv"
    log: "logs/" + TECH + "/kraken/{sample}_count_length.log"
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
