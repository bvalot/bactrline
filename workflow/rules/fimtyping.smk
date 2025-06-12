rule all_fimtyping:
    input:
        expand("data/intermediate/fimtyping/{sample}_FIM.tsv", sample=samples.index)


rule fimtyping:
    input:
        filtered_contig = "data/intermediate/filtered_contigs/{sample}.fasta"
    output:
        fimtyping_tsv = "data/intermediate/fimtyping/{sample}_FIM.tsv"
    log: "logs/fimtyping/{sample}.log"
    params:
        extra_params = config['fimtyping']['extra_params']
    conda:
        "../envs/pymlst.yml"
    shell:
        """
        pyTyper search -o {output.fimtyping_tsv} \
        {params.extra_params} \
        fim \
        {input.filtered_contig} > {log} 2>&1
        """

