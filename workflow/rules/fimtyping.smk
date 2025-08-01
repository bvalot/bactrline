rule all_fimtyping:
    input:
        expand("data/intermediate/fimtyping/{sample}_FIM.tsv", sample=samples.index)


rule fimtyping:
    input:
        polished_contig = lambda wc: (f"data/intermediate/polished_contigs/{wc.sample}/medaka/consensus.fasta" if wc.sample in ALL_NANOPORE_SAMPLES else f"data/intermediate/polished_contigs/{wc.sample}/nextpolish/genome.nextpolish.fasta"),
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
        {input.polished_contig} > {log} 2>&1
        """

