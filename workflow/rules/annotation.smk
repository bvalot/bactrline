rule all_annotation: 
    input:
        "workflow/reports/annotation_report.tsv",
        "workflow/reports/gene_amr_summary.tsv"


rule annotation:
    input:
        amr_tsv = expand("data/intermediate/amr/{sample}_AMR.tsv", sample=samples.index),
        pymlst_file = expand("data/intermediate/pymlst/{sample}_MLST.tsv", sample=samples.index),
        clermont_tsv = expand("data/intermediate/clermontyping/{sample}_CLMT.tsv", sample=samples.index) if config['configuration']['species'] == 'Escherichia coli' else [],
        fim_tsv = expand("data/intermediate/fimtyping/{sample}_FIM.tsv", sample=samples.index) if config['configuration']['species'] == 'Escherichia coli' else [],
        spa_tsv = expand("data/intermediate/spatyping/{sample}_SPA.tsv", sample=samples.index) if config['configuration']['species'] == 'Staphylococcus aureus' else [],
        platon_tsv = expand("data/intermediate/platon/{sample}/{sample}.tsv", sample=samples.index) if config['configuration']['plasmid_tool'] == 'platon' or config['configuration']['plasmid_tool'] == 'platon,plasclass' else [],
        plasclass_tsv = expand("data/intermediate/plasclass/{sample}.tsv", sample=samples.index) if config['configuration']['plasmid_tool'] == 'plasclass' or config['configuration']['plasmid_tool'] == 'platon,plasclass' else []
    output:
        report = "results/annotation_report.tsv",
        gene_report = "results/gene_amr_summary.tsv"
    conda:
        "../envs/R.yml"
    log:
        "logs/annotation/annotation.log"
    params:
        species = config['configuration']['species'],
        plasmid_tool = config['configuration']['plasmid_tool'],
        min_length = config['annotation']['min_length'],
        plas_thresh_platon = config['annotation']['platon']['plasmid_threshold'],
        chr_thresh_platon = config['annotation']['platon']['chromosome_threshold'],
        plas_thresh_palsclass = config['annotation']['plasclass']['plasmid_threshold'],
        chr_thresh_plasclass = config['annotation']['plasclass']['chromosome_threshold']
    script: 
        "../scripts/report_annotation.R"

