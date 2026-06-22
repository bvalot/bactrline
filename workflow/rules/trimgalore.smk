def get_sample_file(wildcards):
    sample = wildcards.sample
    if samples.loc[sample, "type"] == "illumina":
        return "illumina"
    elif samples.loc[sample, "type"] == "illumina sra":
        return "sra"


rule all_trimgalore:
    input:
        expand("data/intermediate/illumina/trimgalore/{sample}/{sample}_val_1.fq.gz", sample=ALL_ILLUMINA_SAMPLES),
        expand("data/intermediate/illumina/trimgalore/{sample}/{sample}_val_2.fq.gz", sample=ALL_ILLUMINA_SAMPLES)
        
        
rule trimgalore:
    input:
        read_1 = branch(
            get_sample_file,
            cases={
                "illumina": lambda wildcards: illumina.loc[wildcards.sample, "R1"],
                "sra": "data/raw/sra/{sample}/{sample}_1.fastq.gz"
            }
        ),
        read_2 = branch(
            get_sample_file,
            cases={
                "illumina": lambda wc: illumina.loc[wc.sample, "R2"],
                "sra": "data/raw/sra/{sample}/{sample}_2.fastq.gz"
            }
        )
    output:
        trimmed_read1 = 'data/intermediate/illumina/trimgalore/{sample}/{sample}_val_1.fq.gz',
        trimmed_read2 = 'data/intermediate/illumina/trimgalore/{sample}/{sample}_val_2.fq.gz'
    log: "logs/illumina/trimgalore/{sample}.log"
    conda:
        "../envs/trimgalore.yml"
    params:
        output_dir = "data/intermediate/illumina/trimgalore/{sample}/",
        min_len = config['trimgalore']['minimum_length'],
        quality_cut = config['trimgalore']['quality_cutoff'],
        extra_params = config['trimgalore']['extra_params']
    shell:   
        """
            trim_galore -o {params.output_dir} \
            -q {params.quality_cut} \
            --length {params.min_len} \
            --basename {wildcards.sample} \
            {params.extra_params} \
            {input.read_1} \
            {input.read_2} &> {log}
        """

