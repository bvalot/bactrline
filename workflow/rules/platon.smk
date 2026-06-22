rule all_platon:
    input:
        expand("data/intermediate/" + TECH + "/platon/{sample}/{sample}.tsv", sample=samples.index),



rule platon:
    input:
        filtered_contig = "data/intermediate/" + TECH + "/filtered_contigs/{sample}.fasta",
        database = config['configuration']['platon_db']
    output:
        platon_file = "data/intermediate/" + TECH + "/platon/{sample}/{sample}.tsv"
    threads: config['resources']['threads']
    conda:
        "../envs/platon.yml"
    log: "logs/" + TECH + "/platon/{sample}.log"
    params:
        output_dir = "data/intermediate/" + TECH + "/platon/{sample}",
        extra_params = config['platon']['extra_params']
    shell:
        """
        platon --db {input.database} \
        --prefix {wildcards.sample} \
        --output {params.output_dir} \
        --characterize \
        --threads {threads} \
        {params.extra_params} \
        {input.filtered_contig} > {log} 2>&1
        """

