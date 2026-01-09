def get_contig_file(wildcards):
    sample = wildcards.sample
    if samples.loc[sample, "type"] == "genome assembled":
        return "genome assembled"
    elif samples.loc[sample, "type"] == "nanopore" or samples.loc[sample, "type"] == "nanopore sra":
        return "nanopore"
    elif samples.loc[sample, "type"] == "illumina" or samples.loc[sample, "type"] == "illumina sra":
        return "illumina"


rule all_filter:
    input:
        expand('data/intermediate/filtered_contigs/{sample}.fasta', sample=samples.index)


rule filter:
    input:
        contigs_file = branch(
            get_contig_file,
            cases={
                "genome assembled": lambda wc : assembled.loc[wc.sample, "file"],
                "nanopore": "data/intermediate/polishing/{sample}/consensus.fasta",
                "illumina": "data/intermediate/assembled/{sample}_assembled/contigs.fasta"
            }
        )
    output:
        filtered_contigs_file = "data/intermediate/filtered_contigs/{sample}.fasta"
    log:
        "logs/filter_contig/{sample}.log"
    params:
        info_file = "data/intermediate/flye/{sample}/assembly_info.txt",
        cov_contig = config['filter_contigs']['coverage'],
        len_contig = config['filter_contigs']['length']
    script:
        "../scripts/filter_contigs.py"

