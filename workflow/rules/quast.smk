### QUAST ###

rule all_quast:
    input:
        expand("data/intermediate/" + TECH + "/quast/{sample}/transposed_report.tsv", sample=samples.index),



rule quast:
    input:
        filtered_contig = "data/intermediate/" + TECH + "/filtered_contigs/{sample}.fasta"
    output:
        quast_report = "data/intermediate/" + TECH + "/quast/{sample}/transposed_report.tsv"
    log: "logs/" + TECH + "/quast/{sample}.log"
    conda:
        "../envs/quast.yml"
    params:
        reference_file = config['configuration']['reference'],
        quast_directory = "data/intermediate/" + TECH + "/quast/{sample}/",
        extra_params = config['quality']['quast']['extra_params']
    shell:
        """
        quast {input.filtered_contig} \
        -o {params.quast_directory} \
        -r {params.reference_file} \
        {params.extra_params} > {log} 2>&1
        """
