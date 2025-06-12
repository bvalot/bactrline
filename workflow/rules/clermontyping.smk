rule all_clermontyping:
    input:
        expand("data/intermediate/clermontyping/{sample}_CLMT.tsv", sample=samples.index)
        

rule clermontyping:
    input:
        filtered_contig = "data/intermediate/filtered_contigs/{sample}.fasta"
    output:
        clermontyping_tsv = "data/intermediate/clermontyping/{sample}_CLMT.tsv"
    log: "logs/clermontyping/{sample}.log"
    params:
        extra_params = config['clermontyping']['extra_params']
    conda:
        "../envs/pymlst.yml"
    shell:
        """	
        pyTyper search -o {output.clermontyping_tsv} \
        {params.extra_params} \
        clmt \
        {input.filtered_contig} > {log} 2>&1
        """

