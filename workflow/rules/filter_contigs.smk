def get_contig_file(wildcards):
    sample = wildcards.sample
    if samples.loc[sample, "type"] == "assembled":
        return "assembled"
    elif samples.loc[sample, "type"] == "nanopore" or samples.loc[sample, "type"] == "nanopore sra":
        return "nanopore"
    elif samples.loc[sample, "type"] == "illumina" or samples.loc[sample, "type"] == "illumina sra":
        return "illumina"


rule all_filter:
    input:
        expand('data/intermediate/' + TECH + '/filtered_contigs/{sample}.fasta', sample=samples.index),



rule filter:
    input:
        contigs_file = branch(
            get_contig_file,
            cases={
                "assembled": lambda wc : assembled.loc[wc.sample, "file"],
                "nanopore": "data/intermediate/" + TECH + "/polishing/{sample}/consensus.fasta",
                "illumina": "data/intermediate/" + TECH + "/assembled/{sample}_assembled/contigs.fasta"
            }
        )
    output:
        filtered_contigs_file = "data/intermediate/" + TECH + "/filtered_contigs/{sample}.fasta"
    log:
        "logs/" + TECH + "/filter_contig/{sample}.log"
    params:
        info_file = "data/intermediate/nanopore/flye/{sample}/assembly_info.txt",
        cov_contig = config['filter_contigs']['coverage'],
        len_contig = config['filter_contigs']['length']
    script:
        "../scripts/filter_contigs.py"

