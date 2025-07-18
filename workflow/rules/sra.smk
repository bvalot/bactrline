rule all_sra:
    input:
        sra_1 = expand("data/raw/sra/{sample}/{sample}_1.fastq.gz", sample=SRA_ILLUMINA_SAMPLES),
        sra_2 = expand("data/raw/sra/{sample}/{sample}_2.fastq.gz", sample=SRA_ILLUMINA_SAMPLES),
        sra = expand("data/raw/sra/{sample}/{sample}.fastq.gz", sample=SRA_NANOPORE_SAMPLES)


rule sra_illumina:
    output:
        fastq_file_1 = "data/raw/sra/{sample}/{sample}_1.fastq.gz",
        fastq_file_2 = "data/raw/sra/{sample}/{sample}_2.fastq.gz"
    log:
        "logs/sra/{sample}.log"
    conda:
        "../envs/sra.yml"
    params:
        sra_file = lambda wildcards: sra.loc[wildcards.sample, "sra_file/sra_ID"],
        out_dir = "data/raw/sra/{sample}/"
    shell:
        """
        fasterq-dump {params.sra_file} \
        --split-files \
        --outdir {params.out_dir} > {log} 2>&1
        
        gzip {params.out_dir}{wildcards.sample}_1.fastq
        gzip {params.out_dir}{wildcards.sample}_2.fastq
        """
        
        
rule sra_nanopore:
    output:
        fastq_file = "data/raw/sra/{sample}/{sample}.fastq.gz"
    log:
        "logs/sra/{sample}.log"
    conda:
        "../envs/sra.yml"
    params:
        sra_file = lambda wildcards: sra.loc[wildcards.sample, "sra_file/sra_ID"],
        out_dir = "data/raw/sra/{sample}/"
    shell:
        """
        fasterq-dump {params.sra_file} \
        --split-files \
        --outdir {params.out_dir} > {log} 2>&1
        
        gzip {params.out_dir}{wildcards.sample}.fastq
        """
