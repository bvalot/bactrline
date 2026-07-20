### MultiQC — Merge all QC reports (FastQC + NanoPlot) into a single report ###

def multiqc_inputs():
    """Return directories to scan based on available data."""
    dirs = []
    if len(ALL_ILLUMINA_SAMPLES) > 0:
        dirs.append("data/intermediate/QC_raw/")
        dirs.append("data/intermediate/QC_trimmed/")
    if len(ALL_NANOPORE_SAMPLES) > 0:
        dirs.append("data/intermediate/QC_raw/")
        dirs.append("data/intermediate/QC_trimmed/")
    return dirs


rule all_multiqc:
    input:
        "results/QC_report/multiqc_report.html"


rule multiqc:
    input:
        fastqc_raw = expand("data/intermediate/QC_raw/{sample}/{sample}_R1_001_fastqc.zip", sample=ALL_ILLUMINA_SAMPLES) +
                     expand("data/intermediate/QC_raw/{sample}/{sample}_R2_001_fastqc.zip", sample=ALL_ILLUMINA_SAMPLES),
        fastqc_trimmed = expand("data/intermediate/QC_trimmed/{sample}/{sample}_val_1_fastqc.zip", sample=ALL_ILLUMINA_SAMPLES) +
                         expand("data/intermediate/QC_trimmed/{sample}/{sample}_val_2_fastqc.zip", sample=ALL_ILLUMINA_SAMPLES),
        # NanoPlot outputs (Nanopore) 
        nanoplot_raw = expand("data/intermediate/QC_raw/{sample}/{sample}_raw_NanoStats.txt", sample=ALL_NANOPORE_SAMPLES),
        nanoplot_filtered = expand("data/intermediate/QC_trimmed/{sample}/{sample}_filtered_NanoStats.txt", sample=ALL_NANOPORE_SAMPLES)
    output:
        report = "results/QC_report/multiqc_report.html"
    log: "logs/multiqc/multiqc.log"
    conda: "../envs/multiqc.yml"
    params:
        config = "config/multiqc_config.yaml",
        outdir = "results/QC_report/"
    shell:
        """
        mkdir -p {params.outdir}
        
        multiqc \
            --config {params.config} \
            --outdir {params.outdir} \
            --filename multiqc_report.html \
            --no-data-dir \
            --force \
            data/intermediate/QC_raw/ \
            data/intermediate/QC_trimmed/ \
            &> {log}
        """


### all_qc — Full QC chain ###

rule all_qc:
    input:
        # Illumina: ensure trimmed reads are generated
        expand("data/intermediate/trimgalore/{sample}/{sample}_val_1.fq.gz", sample=ALL_ILLUMINA_SAMPLES),
        expand("data/intermediate/trimgalore/{sample}/{sample}_val_2.fq.gz", sample=ALL_ILLUMINA_SAMPLES),
        # Nanopore: ensure NanoStats files are generated
        expand("data/intermediate/QC_raw/{sample}/{sample}_raw_NanoStats.txt", sample=ALL_NANOPORE_SAMPLES),
        expand("data/intermediate/QC_trimmed/{sample}/{sample}_filtered_NanoStats.txt", sample=ALL_NANOPORE_SAMPLES),
        # MultiQC report
        "results/QC_report/multiqc_report.html"
