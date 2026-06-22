rule all_amrfinder: 
    input:
        expand("data/intermediate/" + TECH + "/amr/{sample}_AMR.tsv", sample=samples.index),



rule amrfinder:
    input:
        filtered_contig = "data/intermediate/" + TECH + "/filtered_contigs/{sample}.fasta",
        setup = "resources/database/amr/amrfinder.setup"
    output:
        amr_tsv = "data/intermediate/" + TECH + "/amr/{sample}_AMR.tsv"
    conda:
        "../envs/amrfinder.yml"
    log: 
        "logs/" + TECH + "/amr/{sample}.log" 
    params:
        species = config['amrfinder']['species'],
        extra_params = config['amrfinder']['extra_params']
    run: 
        if config['amrfinder']['species'] == '':
            shell("""
            amrfinder -n {input.filtered_contig} \
            -o {output.amr_tsv} \
            --name {wildcards.sample} \
            {params.extra_params} \
	    &> {log}
            """)
        else:
            shell("""
            amrfinder -n {input.filtered_contig} \
            -o {output.amr_tsv} \
            --organism {params.species} \
            --name {wildcards.sample} \
            --plus \
            {params.extra_params} \
	    &> {log}	    
            """)

