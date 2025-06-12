rule all_filter:
    input:
        expand('data/intermediate/filtered_contigs/{sample}.fasta', sample=samples.index)


rule filter:
    input:
        contigs_file = lambda wc: (f"data/intermediate/flye/{wc.sample}/assembly.fasta" if wc.sample in ALL_NANOPORE_SAMPLES else f"data/intermediate/assembled/{wc.sample}_assembled/contigs.fasta")
    output:
        filtered_contigs_file = "data/intermediate/filtered_contigs/{sample}.fasta"
    params:
        info_file = "data/intermediate/flye/{sample}/assembly_info.txt",
        cov_contig = config['filter_contigs']['coverage'],
        len_contig = config['filter_contigs']['length']
    script:
        "../scripts/filter_contigs.py"

