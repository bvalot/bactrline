rule all_flye:
    input:
        expand("data/intermediate/contigs/{sample}.fasta", sample=ALL_NANOPORE_SAMPLES)
        
        
rule flye:
    input:
        trim_read = "data/intermediate/filtlong/{sample}.fastq.gz"
    output:
        contig_file = "data/intermediate/flye/{sample}/assembly.fasta"
    threads: config['resources']['threads']
    resources:
        mem_mb = config['resources']['mem_mb']
    log: "logs/flye/{sample}.log"
    conda:
        "../envs/flye.yml"
    params:
        output_dir = "data/intermediate/flye/{sample}/",
        extra_params = config['flye']['extra_params']
    shell:   
        """
        mkdir -p {params.output_dir}
        
        flye --nano-hq {input.trim_read} \
        --out-dir {params.output_dir} \
        --threads {threads} \
        {params.extra_params} > {log} 2>&1
        """

