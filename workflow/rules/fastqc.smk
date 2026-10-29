### FastQC on raw reads (before TrimGalore) ###

rule all_fastqc_raw:
    input:
        expand("data/intermediate/QC_raw/{sample}/{sample}_R1_001_fastqc.zip", sample=ALL_ILLUMINA_SAMPLES),
        expand("data/intermediate/QC_raw/{sample}/{sample}_R2_001_fastqc.zip", sample=ALL_ILLUMINA_SAMPLES)


rule fastqc_raw:
    input:
        read_1 = branch(
            get_sample_file,
            cases={
                "illumina": lambda wc: illumina.loc[wc.sample, "R1"],
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
        zip_1 = "data/intermediate/QC_raw/{sample}/{sample}_R1_001_fastqc.zip",
        zip_2 = "data/intermediate/QC_raw/{sample}/{sample}_R2_001_fastqc.zip"
    log: "logs/QC_raw/{sample}.log"
    threads: config['resources']['threads']
    conda:
        "../envs/fastqc.yml"
    params:
        outdir = "data/intermediate/QC_raw/{sample}/"
    shell:
        """
        mkdir -p {params.outdir}

        # Create temporary directory with symlinks to standardize input filenames
        # FastQC names outputs after input filenames, so we control the name here
        tmpdir=$(mktemp -d)
        trap "rm -rf $tmpdir" EXIT ERR

        # Create symlinks with expected naming convention (without _S* patterns)
        # Use {wildcards.sample} to access the sample wildcard value
        ln -s $(readlink -f {input.read_1}) $tmpdir/{wildcards.sample}_R1_001.fastq.gz
        ln -s $(readlink -f {input.read_2}) $tmpdir/{wildcards.sample}_R2_001.fastq.gz

        # Run FastQC on the symlinked files
        # Output will have the expected names: {wildcards.sample}_R1_001_fastqc.zip
        fastqc -t {threads} -o {params.outdir} \
            --noextract \
            --quiet \
            $tmpdir/{wildcards.sample}_R1_001.fastq.gz \
            $tmpdir/{wildcards.sample}_R2_001.fastq.gz &> {log}
        """


### FastQC on trimmed reads (after TrimGalore) ###

rule all_fastqc_trimmed:
    input:
        expand("data/intermediate/QC_trimmed/{sample}/{sample}_val_1_fastqc.zip", sample=ALL_ILLUMINA_SAMPLES),
        expand("data/intermediate/QC_trimmed/{sample}/{sample}_val_2_fastqc.zip", sample=ALL_ILLUMINA_SAMPLES)


rule fastqc_trimmed:
    input:
        trimmed_1 = "data/intermediate/trimgalore/{sample}/{sample}_val_1.fq.gz",
        trimmed_2 = "data/intermediate/trimgalore/{sample}/{sample}_val_2.fq.gz"
    output:
        zip_1 = "data/intermediate/QC_trimmed/{sample}/{sample}_val_1_fastqc.zip",
        zip_2 = "data/intermediate/QC_trimmed/{sample}/{sample}_val_2_fastqc.zip"
    log: "logs/QC_trimmed/{sample}.log"
    threads: config['resources']['threads']
    conda:
        "../envs/fastqc.yml"
    params:
        outdir = "data/intermediate/QC_trimmed/{sample}/"
    shell:
        """
        mkdir -p {params.outdir}
        fastqc -t {threads} -o {params.outdir} \
            --noextract \
            --quiet \
            {input.trimmed_1} {input.trimmed_2} &> {log}
        """
