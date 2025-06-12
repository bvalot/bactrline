rule all_amrfinder: 
    input:
        expand("data/intermediate/amr/{sample}_AMR.tsv", sample=samples.index)


rule amrfinder:
    input:
        filtered_contig = "data/intermediate/filtered_contigs/{sample}.fasta",
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
        amrfinder -n {input.filtered_contig} \
        -o {output.amr_tsv} \
        --organism {params.species} \
        --name {wildcards.sample} \
        --plus \
        --log {log} \
        -q \
        {params.extra_params}
        """

