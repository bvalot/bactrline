rule all_pymlst:
    input:
        expand("data/intermediate/pymlst/{sample}_MLST.tsv", sample=samples.index)


rule pymlst:
    input:
        filtered_contig = "data/intermediate/filtered_contigs/{sample}.fasta",
        database = config['configuration']['pymlst_db']
    output:
        pymlst_file = "data/intermediate/pymlst/{sample}_MLST.tsv"
    conda:
        "../envs/pymlst.yml"
    log: "logs/pymlst/{sample}.log"
    params:
        identity = config['pymlst']['min_identity'],
        coverage = config['pymlst']['min_coverage'],
        extra_params = config['pymlst']['extra_params']
    shell:
        """
        claMLST search -i {params.identity} \
        -c {params.coverage} \
        --output {output.pymlst_file} \
        {params.extra_params} \
        {input.database} \
        {input.filtered_contig} > {log} 2>&1
        """

