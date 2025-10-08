rule all_medaka:
    input:
        expand("data/intermediate/polishing/{sample}/consensus.fasta", sample=ALL_NANOPORE_SAMPLES)


rule medaka:
    input:
        trim_read = "data/intermediate/filtlong/{sample}.fastq.gz",
        contigs_file = "data/intermediate/flye/{sample}/assembly.fasta"
    output:
        polished_contigs_file = "data/intermediate/polishing/{sample}/consensus.fasta"
    conda:
        "../envs/medaka.yml"
    threads: config['resources']['threads']
    resources:
        mem_mb = config['resources']['mem_mb']
    log: "logs/polishing/{sample}.log"
    params:
        extra_params = config['medaka']['extra_params']
    shell:
        """
            medaka_consensus {params.extra_params} -i {input.trim_read} \
            -d {input.contigs_file} -t {threads} -f \
            -o data/intermediate/polishing/{wildcards.sample} &> {log}
        """
