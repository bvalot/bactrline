### NanoPlot on raw reads (before Filtlong) ###

rule all_nanoplot_raw:
    input:
        expand("data/intermediate/QC_raw/{sample}/{sample}_raw_NanoStats.txt", sample=ALL_NANOPORE_SAMPLES)


rule nanoplot_raw:
    input:
        raw_read = branch(
            get_nanopore_file,
            cases={
                "nanopore": lambda wc: nanopore.loc[wc.sample, "folder/file"],
                "sra": "data/raw/sra/{sample}/{sample}.fastq.gz"
            }
        )
    output:
        stats = "data/intermediate/QC_raw/{sample}/{sample}_raw_NanoStats.txt"
    log: "logs/QC_raw/{sample}.log"
    threads: config['resources']['threads']
    conda:
        "../envs/nanoplot.yml"
    params:
        outdir = "data/intermediate/QC_raw/{sample}/"
    shell:
        """
        mkdir -p {params.outdir}

        # Get input path
        read_path="{input.raw_read}"
        read_path="${{read_path%/}}"

        if [ -d "$read_path" ]; then
            # Input is a directory: concatenate all FASTQ files
            NanoPlot --threads {threads} \
                --outdir {params.outdir} \
                --fastq "$read_path"/*.fastq.gz \
                --prefix {wildcards.sample}_raw_ \
                --no_static &> {log}
        else
            # Input is a single file
            NanoPlot --threads {threads} \
                --outdir {params.outdir} \
                --fastq "$read_path" \
                --prefix {wildcards.sample}_raw_ \
                --no_static &> {log}
        fi

        # Supprimer le fichier NanoStats_post_filtering parasite si présent
        rm -f {params.outdir}{wildcards.sample}_raw_NanoStats_post_filtering.txt
        """


### NanoPlot on filtered reads (after Filtlong) ###
# IMPORTANT: output goes to QC_trimmed/ so MultiQC path_filters can distinguish raw vs filtered

rule all_nanoplot_filtered:
    input:
        expand("data/intermediate/QC_trimmed/{sample}/{sample}_filtered_NanoStats.txt", sample=ALL_NANOPORE_SAMPLES)


rule nanoplot_filtered:
    input:
        trim_read = "data/intermediate/filtlong/{sample}.fastq.gz"
    output:
        stats = "data/intermediate/QC_trimmed/{sample}/{sample}_filtered_NanoStats.txt"
    log: "logs/QC_trimmed/{sample}.log"
    threads: config['resources']['threads']
    conda:
        "../envs/nanoplot.yml"
    params:
        outdir = "data/intermediate/QC_trimmed/{sample}/"
    shell:
        """
        mkdir -p {params.outdir}

        NanoPlot --threads {threads} \
            --outdir {params.outdir} \
            --fastq {input.trim_read} \
            --prefix {wildcards.sample}_filtered_ \
            --no_static &> {log}

        # Supprimer le fichier NanoStats_post_filtering parasite si présent
        rm -f {params.outdir}{wildcards.sample}_filtered_NanoStats_post_filtering.txt
        """


### Combined target rule ###

rule all_nanoplot:
    input:
        expand("data/intermediate/QC_raw/{sample}/{sample}_raw_NanoStats.txt", sample=ALL_NANOPORE_SAMPLES),
        expand("data/intermediate/QC_trimmed/{sample}/{sample}_filtered_NanoStats.txt", sample=ALL_NANOPORE_SAMPLES)
