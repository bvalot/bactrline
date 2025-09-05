rule all_medaka:
    input:
        expand("data/intermediate/polished_contigs/{sample}/polished_contigs.fasta", sample=ALL_NANOPORE_SAMPLES)


rule medaka:
    input:
        trim_read = "data/intermediate/filtlong/{sample}.fastq.gz",
        filtered_contigs_file = "data/intermediate/filtered_contigs/{sample}.fasta"
    output:
        polished_contigs_file = "data/intermediate/polished_contigs/{sample}/medaka/consensus.fasta"
    conda:
        "../envs/medaka.yml"
    threads: config['resources']['threads']
    resources:
        mem_mb = config['resources']['mem_mb']
    log: "logs/polishing/{sample}_nextpolish.log"
    params:
        assembly_dir = "data/intermediate/assembled/{sample}_assembled",
        extra_params = config['assembly']['extra_params']
    shell:
        """
            medaka_consensus -i {input.trim_read} -d {input.filtered_contigs_file} -o data/intermediate/polished_contigs/{wildcards.sample}/medaka
        """


