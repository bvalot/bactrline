rule all_filtlong:
    input:
        expand("data/intermediate/filtlong/{sample}.fastq.gz", sample=ALL_NANOPORE_SAMPLES)
        
        
rule filtlong:
    input:
        read = lambda wc: (nanopore.loc[wc.sample, "folder/file"] if wc.sample in nanopore.index else []),
        sra = lambda wc: (f"data/raw/sra/{wc.sample}/{wc.sample}.fastq.gz" if (wc.sample in sra.index and sra.loc[wc.sample, "tech"] == "nanopore") else [])
    output:
        trim_read = "data/intermediate/filtlong/{sample}.fastq.gz"
    log: "logs/filtlong/{sample}.log"
    conda:
        "../envs/filtlong.yml"
    params:
        min_length = config['filtlong']['min_length'],
        percent = config['filtlong']['percent'],
        extra_params = config['filtlong']['extra_params']
    shell:
        """
        if [ "{input.read}" != "" ]; then
            input_read="{input.read}"
        else
            input_read="{input.sra}"
        fi
        
        read_path="${{input_read%/}}"
        if [ -d "$read_path" ]; then
            cat "$read_path"/*.fastq.gz > "$read_path"/all_{wildcards.sample}.fastq.gz
            filtlong --min_length {params.min_length} \
            --keep_percent {params.percent} \
            {params.extra_params} \
            "$read_path"/all_{wildcards.sample}.fastq.gz 2> {log} | gzip > {output.trim_read}
        else
            filtlong --min_length {params.min_length} \
            --keep_percent {params.percent} \
            {params.extra_params} \
            "$read_path" 2> {log} | gzip > {output.trim_read}
        fi
        """

