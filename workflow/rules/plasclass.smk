rule all_plasclass:
    input:
        expand("data/intermediate/plasclass/{sample}.tsv", sample=samples.index)


rule plasclass:
    input:
        filtered_contig = "data/intermediate/filtered_contigs/{sample}.fasta"
    output:
        plasclass_file = "data/intermediate/plasclass/{sample}.tsv"
    conda:
        "../envs/plasclass.yml"
    log: "logs/plasclass/{sample}.log"
    params:
        extra_params = config['plasclass']['extra_params']
    shell:
        """
        classify_fasta.py \
        --fasta {input.filtered_contig} \
        --outfile {output.plasclass_file} \
        {params.extra_params} > {log} 2>&1
        """

