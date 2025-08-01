rule all_plasclass:
    input:
        expand("data/intermediate/plasclass/{sample}.tsv", sample=samples.index)


rule plasclass:
    input:
        polished_contig = lambda wc: (f"data/intermediate/polished_contigs/{wc.sample}/medaka/consensus.fasta" if wc.sample in ALL_NANOPORE_SAMPLES else f"data/intermediate/polished_contigs/{wc.sample}/nextpolish/genome.nextpolish.fasta"),
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
        --fasta {input.polished_contig} \
        --outfile {output.plasclass_file} \
        {params.extra_params} > {log} 2>&1
        """

