rule all_amrfinder: 
    input:
        expand("data/intermediate/amr/{sample}_AMR.tsv", sample=samples.index)


rule amrfinder:
    input:
        polished_contig = lambda wc: (f"data/intermediate/polished_contigs/{wc.sample}/medaka/consensus.fasta" if wc.sample in ALL_NANOPORE_SAMPLES else f"data/intermediate/polished_contigs/{wc.sample}/nextpolish/genome.nextpolish.fasta"),
        setup = "resources/database/amr/amrfinder.setup"
    output:
        amr_tsv = "data/intermediate/amr/{sample}_AMR.tsv"
    conda:
        "../envs/amrfinder.yml"
    log: 
        "logs/amr/{sample}.log" 
    params:
        species = config['amrfinder']['species'],
        extra_params = config['amrfinder']['extra_params']
    shell: 
        """
        amrfinder -n {input.polished_contig} \
        -o {output.amr_tsv} \
        --organism {params.species} \
        --name {wildcards.sample} \
        --plus \
        --log {log} \
        -q \
        {params.extra_params}
        """

