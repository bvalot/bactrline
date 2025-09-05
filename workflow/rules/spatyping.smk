rule all_spatyping: 
    input:
        expand("data/intermediate/spatyping/{sample}_SPA.tsv", sample=samples.index)


rule spatyping:
    input:
        polished_contig = lambda wc: (f"data/intermediate/polished_contigs/{wc.sample}/medaka/consensus.fasta" if wc.sample in ALL_NANOPORE_SAMPLES else f"data/intermediate/polished_contigs/{wc.sample}/nextpolish/genome.nextpolish.fasta"),
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
        {input.polished_contig} > {log} 2>&1
        """

