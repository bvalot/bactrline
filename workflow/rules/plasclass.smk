rule all_plasclass:
    input:
        expand("data/intermediate/" + TECH + "/plasclass/{sample}.tsv", sample=samples.index),
        


rule plasclass:
    input:
        filtered_contig = "data/intermediate/" + TECH + "/filtered_contigs/{sample}.fasta"
    output:
        plasclass_file = "data/intermediate/" + TECH + "/plasclass/{sample}.tsv"
    conda:
        "../envs/plasclass.yml"
    log: "logs/" + TECH + "/plasclass/{sample}.log"
    params:
        extra_params = config['plasclass']['extra_params']
    shell:
        """
        classify_fasta.py \
        --fasta {input.filtered_contig} \
        --outfile {output.plasclass_file} \
        {params.extra_params} > {log} 2>&1
        """

