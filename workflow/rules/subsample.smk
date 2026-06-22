rule all_subsample:
    input:
        expand("data/intermediate/" + TECH + "/subsample/{sample}_val_1_sub.fastq.gz", sample=ALL_ILLUMINA_SAMPLES),
        expand("data/intermediate/" + TECH + "/subsample/{sample}_val_2_sub.fastq.gz", sample=ALL_ILLUMINA_SAMPLES)


rule subsample:
    input:
        trimmed_read1='data/intermediate/' + TECH + '/trimgalore/{sample}/{sample}_val_1.fq.gz',
        trimmed_read2='data/intermediate/' + TECH + '/trimgalore/{sample}/{sample}_val_2.fq.gz'
    output:
        sub_read1 = "data/intermediate/" + TECH + "/subsample/{sample}_val_1_sub.fastq.gz",
        sub_read2 = "data/intermediate/" + TECH + "/subsample/{sample}_val_2_sub.fastq.gz"
    log: "logs/illumina/subsample/{sample}_subsample.log"
    conda:
        "../envs/subsample.yml"
    params: 
        genomesize =  config['configuration']['genome_size'],
        coverage = config['subsample']['coverage'],
        extra_params = config['subsample']['extra_params'],
        subsample_directory = "data/intermediate/" + TECH + "/subsample/",
        script_subsample = "workflow/scripts/sub_sample.py"
    shell:
        """
            python3 {params.script_subsample} \
            -d {params.subsample_directory} \
            -c {params.coverage} \
            -r {input.trimmed_read1} \
            -l {input.trimmed_read2} \
            --copy \
            {params.extra_params} \
            {params.genomesize} > {log} 2>&1
        """
   
