### Helper: determine which MultiQC reports are expected based on samplesheet ###

def multiqc_targets():
    """Return the list of MultiQC reports to produce based on which
    technologies are present in the samplesheet."""
    targets = []
    if len(ALL_ILLUMINA_SAMPLES) > 0:
        targets.append("results/" + TECH + "/illumina_qc/multiqc_report.html")
    if len(ALL_NANOPORE_SAMPLES) > 0:
        targets.append("results/" + TECH + "/nanoplot_qc/multiqc_report.html")
    return targets


### all_qc — Full QC chain: FastQC/NanoPlot raw + trimmed/filtered + MultiQC per technology ###

rule all_qc:
    input:
        expand("data/intermediate/" + TECH + "/trimgalore/{sample}/{sample}_val_1.fq.gz", sample=ALL_ILLUMINA_SAMPLES),
        expand("data/intermediate/" + TECH + "/trimgalore/{sample}/{sample}_val_2.fq.gz", sample=ALL_ILLUMINA_SAMPLES),
        expand("data/intermediate/" + TECH + "/nanoplot_raw/{sample}/{sample}_raw_NanoStats.txt", sample=ALL_NANOPORE_SAMPLES),
        expand("data/intermediate/" + TECH + "/nanoplot_filtered/{sample}/{sample}_filtered_NanoStats.txt", sample=ALL_NANOPORE_SAMPLES),
        multiqc_targets()


### Internal rule: produces results/illumina/illumina_qc/multiqc_report.html ###

rule multiqc_illumina:
    input:
        raw = expand("data/intermediate/" + TECH + "/fastqc_raw/{sample}_R1_001_fastqc.zip", sample=ALL_ILLUMINA_SAMPLES) +
              expand("data/intermediate/" + TECH + "/fastqc_raw/{sample}_R2_001_fastqc.zip", sample=ALL_ILLUMINA_SAMPLES),
        trimmed = expand("data/intermediate/" + TECH + "/fastqc_trimmed/{sample}_val_1_fastqc.zip", sample=ALL_ILLUMINA_SAMPLES) +
                  expand("data/intermediate/" + TECH + "/fastqc_trimmed/{sample}_val_2_fastqc.zip", sample=ALL_ILLUMINA_SAMPLES)
    output:
        report = "results/" + TECH + "/illumina_qc/multiqc_report.html"
    log: "logs/" + TECH + "/multiqc/multiqc_illumina.log"
    conda:
        "../envs/multiqc.yml"
    params:
        config = "config/multiqc_config.yaml",
        outdir = "results/" + TECH + "/illumina_qc/",
        raw_dir = "data/intermediate/" + TECH + "/fastqc_raw/",
        trimmed_dir = "data/intermediate/" + TECH + "/fastqc_trimmed/"
    shell:
        """
        multiqc \
            --config {params.config} \
            --outdir {params.outdir} \
            --filename multiqc_report.html \
            --no-data-dir \
            --force \
            {params.raw_dir} \
            {params.trimmed_dir} \
            &> {log}
        """


### Internal rule: produces results/nanoplot_qc/multiqc_report.html ###

rule multiqc_nanopore:
    input:
        raw = expand("data/intermediate/" + TECH + "/nanoplot_raw/{sample}/{sample}_raw_NanoStats.txt", sample=ALL_NANOPORE_SAMPLES),
        filtered = expand("data/intermediate/" + TECH + "/nanoplot_filtered/{sample}/{sample}_filtered_NanoStats.txt", sample=ALL_NANOPORE_SAMPLES)
    output:
        report = "results/" + TECH + "/nanoplot_qc/multiqc_report.html"
    log: "logs/" + TECH + "/multiqc/multiqc_nanopore.log"
    conda: "../envs/multiqc.yml"
    params:
        config = "config/multiqc_config.yaml",
        outdir = "results/" + TECH + "/nanoplot_qc/",
        raw_dir = "data/intermediate/" + TECH + "/nanoplot_raw/",
        filtered_dir = "data/intermediate/" + TECH + "/nanoplot_filtered/"
    shell:
        """
        multiqc \
            --config {params.config} \
            --outdir {params.outdir} \
            --filename multiqc_report.html \
            --no-data-dir \
            --force \
            {params.raw_dir} \
            {params.filtered_dir} \
            &> {log}
        """
        
        
        
rule multiqc_nanopore_raw:
    input:
        expand("data/intermediate/" + TECH + "/nanoplot_raw/{sample}/{sample}_raw_NanoStats.txt", sample=ALL_NANOPORE_SAMPLES)
    output:
        report = "results/" + TECH + "/nanoplot_raw_qc/multiqc_report.html"
    log: "logs/" + TECH + "/multiqc/multiqc_nanopore_raw.log"
    conda: "../envs/multiqc.yml"
    params:
        config = "config/multiqc_config.yaml",
        outdir = "results/" + TECH + "/nanoplot_raw_qc/",
        indir = "data/intermediate/" + TECH + "/nanoplot_raw/"
    shell:
        """
        multiqc \
            --config {params.config} \
            --outdir {params.outdir} \
            --filename multiqc_report.html \
            --no-data-dir \
            --force \
            {params.indir} \
            &> {log}
        """

rule multiqc_nanopore_filtered:
    input:
        expand("data/intermediate/" + TECH + "/nanoplot_filtered/{sample}/{sample}_filtered_NanoStats.txt", sample=ALL_NANOPORE_SAMPLES)
    output:
        report = "results/" + TECH + "/nanoplot_filtered_qc/multiqc_report.html"
    log: "logs/" + TECH + "/multiqc/multiqc_nanopore_filtered.log"
    conda: "../envs/multiqc.yml"
    params:
        config = "config/multiqc_config.yaml",
        outdir = "results/" + TECH + "/nanoplot_filtered_qc/",
        indir = "data/intermediate/" + TECH + "/nanoplot_filtered/"
    shell:
        """
        multiqc \
            --config {params.config} \
            --outdir {params.outdir} \
            --filename multiqc_report.html \
            --no-data-dir \
            --force \
            {params.indir} \
            &> {log}
        """


