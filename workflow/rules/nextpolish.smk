rule all_nextpolish:
    input:
        expand("data/intermediate/polished_contigs/{sample}/nextpolish/genome.nextpolish.fasta", sample=ALL_ILLUMINA_SAMPLES)


rule nextpolish:
    input:
        sub_read1 = "data/intermediate/subsample/{sample}_val_1_sub.fastq.gz",
        sub_read2 = "data/intermediate/subsample/{sample}_val_2_sub.fastq.gz",
        filtered_contigs_file = "data/intermediate/filtered_contigs/{sample}.fasta"
    output:
        polished_contigs_file = "data/intermediate/polished_contigs/{sample}/nextpolish/genome.nextpolish.fasta"
    conda:
        "../envs/nextpolish.yml"
    threads: config['resources']['threads']
    resources:
        mem_mb = config['resources']['mem_mb']
    log: "logs/polishing/{sample}_nextpolish.log"
    params:
        assembly_dir = "data/intermediate/assembled/{sample}_assembled",
        extra_params = config['assembly']['extra_params']
    shell:
        """
            echo -e "../../../{input.sub_read1}\n../../../{input.sub_read2}" > data/intermediate/polished_contigs/{wildcards.sample}_sgs.fofn
            echo -e "task = best\ngenome = ../../../{input.filtered_contigs_file}\nsgs_fofn = {wildcards.sample}_sgs.fofn\nworkdir = ./{wildcards.sample}/nextpolish" > data/intermediate/polished_contigs/{wildcards.sample}_run.cfg
            nextPolish data/intermediate/polished_contigs/{wildcards.sample}_run.cfg
            rm data/intermediate/polished_contigs/{wildcards.sample}_run.cfg
            rm data/intermediate/polished_contigs/{wildcards.sample}_sgs.fofn
        """


