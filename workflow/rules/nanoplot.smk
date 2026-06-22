### NanoPlot on raw reads (before Filtlong) ###

rule all_nanoplot_raw:
    input:
        "results/" + TECH + "/nanoplot_raw_qc/multiqc_report.html"


rule nanoplot_raw:
    input:
        branch(
            get_nanopore_file,
            cases={
                "nanopore": lambda wc: nanopore.loc[wc.sample, "folder/file"],
                "sra": "data/raw/sra/" + TECH + "/{sample}/{sample}.fastq.gz"
            }
        )
    output:
        stats = "data/intermediate/" + TECH + "/nanoplot_raw/{sample}/{sample}_raw_NanoStats.txt"
    log: "logs/" + TECH + "/nanoplot_raw/{sample}.log"
    threads: config['resources']['threads']
    conda:
        "../envs/nanoplot.yml"
    params:
        outdir = "data/intermediate/" + TECH + "/nanoplot_raw/{sample}/"
    shell:
        """
        mkdir -p {params.outdir}
        read_path="{input}"
        read_path="${{read_path%/}}"
        if [ -d "$read_path" ]; then
            NanoPlot --threads {threads} \
                --outdir {params.outdir} \
                --fastq "$read_path"/*.fastq.gz \
                --prefix {wildcards.sample}_raw_ \
                --no_static &> {log}
        else
            NanoPlot --threads {threads} \
                --outdir {params.outdir} \
                --fastq "$read_path" \
                --prefix {wildcards.sample}_raw_ \
                --no_static &> {log}
        fi
        """


### NanoPlot on filtered reads (after Filtlong) ###

rule all_nanoplot_filtered:
    input:
        "results/" + TECH + "/nanoplot_filtered_qc/multiqc_report.html"


rule nanoplot_filtered:
    input:
        trim_read = "data/intermediate/" + TECH + "/filtlong/{sample}.fastq.gz"
    output:
        stats = "data/intermediate/" + TECH + "/nanoplot_filtered/{sample}/{sample}_filtered_NanoStats.txt"
    log: "logs/" + TECH + "/nanoplot_filtered/{sample}.log"
    threads: config['resources']['threads']
    conda:
        "../envs/nanoplot.yml"
    params:
        outdir = "data/intermediate/" + TECH + "/nanoplot_filtered/{sample}/"
    shell:
        """
        mkdir -p {params.outdir}
        NanoPlot --threads {threads} \
            --outdir {params.outdir} \
            --fastq {input.trim_read} \
            --prefix {wildcards.sample}_filtered_ \
            --no_static &> {log}
        """


### Combined target rule ###

rule all_nanoplot:
    input:
        expand("data/intermediate/" + TECH + "/nanoplot_raw/{sample}/{sample}_raw_NanoStats.txt", sample=ALL_NANOPORE_SAMPLES),
        expand("data/intermediate/" + TECH + "/nanoplot_filtered/{sample}/{sample}_filtered_NanoStats.txt", sample=ALL_NANOPORE_SAMPLES)
