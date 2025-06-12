rule all_spatyping: 
    input:
        expand("data/intermediate/spatyping/{sample}_SPA.tsv", sample=samples.index)


rule spatyping:
    input:
        filtered_contig = "data/intermediate/filtered_contigs/{sample}.fasta"
    output:
        spa_tsv = "data/intermediate/spatyping/{sample}_SPA.tsv"
    conda:
        "../envs/pymlst.yml"
    log:
        "logs/spatyping/{sample}.log"
    params:
        extra_params = config['spatyping']['extra_params']
    shell: 
        """
        pyTyper search -o {output.spa_tsv} \
        {params.extra_params} \
        spa \
        {input.filtered_contig} > {log} 2>&1
        """

