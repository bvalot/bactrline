def get_nanopore_file(wildcards):
    sample = wildcards.sample
    if samples.loc[sample, "type"] == "nanopore":
        return "nanopore"
    elif samples.loc[sample, "type"] == "nanopore sra":
        return "sra"


rule all_filtlong:
    input:
        expand("data/intermediate/filtlong/{sample}.fastq.gz", sample=ALL_NANOPORE_SAMPLES)
        
        
rule filtlong:
    input:
        raw_read = branch(
            get_nanopore_file,
            cases={
                "nanopore": lambda wc: nanopore.loc[wc.sample, "folder/file"],
                "sra": "data/raw/sra/{sample}/{sample}.fastq.gz"
            }
        )
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
        read_path="{input.raw_read}"
        read_path="${{read_path%/}}"
        if [ -d "$read_path" ]; then
		    if [ ! -d "data/raw/nanopore/" ]; then
			    mkdir -p data/raw/nanopore/
			fi
		   	cat "$read_path"/*.fastq.gz > "data/raw/nanopore/{wildcards.sample}.fastq.gz"
            filtlong --min_length {params.min_length} \
            --keep_percent {params.percent} \
            {params.extra_params} \
            "data/raw/nanopore/{wildcards.sample}.fastq.gz" 2> {log} | gzip -5 > "{output.trim_read}"
        else
            filtlong --min_length {params.min_length} \
            --keep_percent {params.percent} \
            {params.extra_params} \
            "$read_path" 2> {log} | gzip -5 > "{output.trim_read}"
        fi
        """

