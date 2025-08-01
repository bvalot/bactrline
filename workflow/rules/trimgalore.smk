rule all_trimgalore:
    input:
        expand("data/intermediate/trimgalore/{sample}/{sample}_val_1.fq.gz", sample=ALL_ILLUMINA_SAMPLES),
        expand("data/intermediate/trimgalore/{sample}/{sample}_val_2.fq.gz", sample=ALL_ILLUMINA_SAMPLES)
        
        
rule trimgalore:
    input:
        read_1 = lambda wildcards: (illumina.loc[wildcards.sample, "R1"] if wildcards.sample in illumina.index else []),
        read_2 = lambda wildcards: (illumina.loc[wildcards.sample, "R2"] if wildcards.sample in illumina.index else []),
        sra_1 = lambda wc: (f"data/raw/sra/{wc.sample}/{wc.sample}_1.fastq.gz" if (wc.sample in sra.index and sra.loc[wc.sample, "tech"] == "illumina") else []),
        sra_2 = lambda wc: (f"data/raw/sra/{wc.sample}/{wc.sample}_2.fastq.gz" if (wc.sample in sra.index and sra.loc[wc.sample, "tech"] == "illumina") else []),
    output:
        trimmed_read1 = 'data/intermediate/trimgalore/{sample}/{sample}_val_1.fq.gz',
        trimmed_read2 = 'data/intermediate/trimgalore/{sample}/{sample}_val_2.fq.gz'
    log: "logs/trimgalore/{sample}.log"
    conda:
        "../envs/trimgalore.yml"
    params:
        output_dir = "data/intermediate/trimgalore/{sample}/",
        min_len = config['trimgalore']['minimum_length'],
        quality_cut = config['trimgalore']['quality_cutoff'],
        extra_params = config['trimgalore']['extra_params']
    shell:   
        """
            if [[ "{input.read_1}" != "" && "{input.read_2}" != "" ]]; then
                input_read_1="{input.read_1}"
                input_read_2="{input.read_2}"
            else
                input_read_1="{input.sra_1}"
                input_read_2="{input.sra_2}"
            fi
            
            trim_galore -o {params.output_dir} \
            -q {params.quality_cut} \
            --length {params.min_len} \
            --basename {wildcards.sample} \
            {params.extra_params} \
            "$input_read_1" \
            "$input_read_2" &> {log}
        """