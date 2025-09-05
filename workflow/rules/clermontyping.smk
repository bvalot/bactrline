rule all_clermontyping:
    input:
        expand("data/intermediate/clermontyping/{sample}_CLMT.tsv", sample=samples.index)
        

rule clermontyping:
    input:
        polished_contig = lambda wc: (f"data/intermediate/polished_contigs/{wc.sample}/medaka/consensus.fasta" if wc.sample in ALL_NANOPORE_SAMPLES else f"data/intermediate/polished_contigs/{wc.sample}/nextpolish/genome.nextpolish.fasta"),
    output:
        clermontyping_tsv = "data/intermediate/clermontyping/{sample}_CLMT.tsv"
    log: "logs/clermontyping/{sample}.log"
    params:
        extra_params = config['clermontyping']['extra_params']
    conda:
        "../envs/pymlst.yml"
    shell:
        """	
        pyTyper search -o {output.clermontyping_tsv} \
        {params.extra_params} \
        clmt \
        {input.polished_contig} > {log} 2>&1
        """

