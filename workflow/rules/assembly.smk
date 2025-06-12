rule all_assembly:
    input:
        expand("data/intermediate/assembled/{sample}_assembled/contigs.fasta", sample=ALL_ILLUMINA_SAMPLES)


rule assembly:
    input:
        sub_read1 = "data/intermediate/subsample/{sample}_val_1_sub.fastq.gz",
        sub_read2 = "data/intermediate/subsample/{sample}_val_2_sub.fastq.gz"
    output:
        contig_file = "data/intermediate/assembled/{sample}_assembled/contigs.fasta"
    conda:
        "../envs/assembly.yml"
    threads: config['resources']['threads']
    resources:
        mem_mb = config['resources']['mem_mb']
    log: "logs/assembly/{sample}_assembly.log"
    params:
        assembly_dir = "data/intermediate/assembled/{sample}_assembled",
        extra_params = config['assembly']['extra_params']
    shell:
        """ 
            spades.py --pe1-1 {input.sub_read1} \
            --pe1-2 {input.sub_read2} \
            -o {params.assembly_dir} \
            --threads {threads} \
            {params.extra_params} > {log} 2>&1
        """


