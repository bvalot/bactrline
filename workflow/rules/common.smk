import pandas as pd
from snakemake.utils import validate
import os

validate(config, "../schemas/config.schema.yml")


# Technology for this run (single-tech pipeline: 'illumina' or 'nanopore')
TECH = config['configuration']['tech']

# load table
samples = pd.read_csv("config/samplesheet.tsv", sep="\t").set_index("ID", drop=False)
samples.index = samples.index.astype(str)
validate(samples, "../schemas/samples.schema.yml")

if os.path.exists("config/assembled.tsv"):
    assembled = pd.read_csv("config/assembled.tsv", sep="\t").set_index("ID", drop=False)
else:
    assembled = pd.read_csv("config/assembled.example.tsv", sep="\t").set_index("ID", drop=False)
assembled.index = assembled.index.astype(str)
validate(assembled, "../schemas/assembled.schema.yml")

if os.path.exists("config/sample_illumina.tsv"):
    illumina = pd.read_csv("config/sample_illumina.tsv", sep="\t").set_index("ID", drop=False)
else:
    illumina = pd.read_csv("config/sample_illumina.example.tsv", sep="\t").set_index("ID", drop=False)
illumina.index = illumina.index.astype(str)
validate(illumina, "../schemas/illumina.schema.yml")

if os.path.exists("config/sample_nanopore.tsv"):
    nanopore = pd.read_csv("config/sample_nanopore.tsv", sep="\t").set_index("ID", drop=False)
else:
    nanopore = pd.read_csv("config/sample_nanopore.example.tsv", sep="\t").set_index("ID", drop=False)
nanopore.index = nanopore.index.astype(str)
validate(nanopore, "../schemas/nanopore.schema.yml")

if os.path.exists("config/sra.tsv"):
    sra = pd.read_csv("config/sra.tsv", sep="\t").set_index("ID", drop=False)
else:
    sra = pd.read_csv("config/sra.example.tsv", sep="\t").set_index("ID", drop=False)
sra.index = sra.index.astype(str)
validate(sra, "../schemas/sra.schema.yml")


ILLUMINA_SAMPLES = samples.index.intersection(illumina.index)
NANOPORE_SAMPLES = samples.index.intersection(nanopore.index)
SRA_ILLUMINA_SAMPLES = samples.index.intersection(sra.index[sra["tech"] == "illumina"])
SRA_NANOPORE_SAMPLES = samples.index.intersection(sra.index[sra["tech"] == "nanopore"])
ALL_ILLUMINA_SAMPLES = set(ILLUMINA_SAMPLES) | set (SRA_ILLUMINA_SAMPLES)
ALL_NANOPORE_SAMPLES = set(NANOPORE_SAMPLES) | set(SRA_NANOPORE_SAMPLES)
ASSEMBLED = samples.index.intersection(assembled.index)


samples["type"] = None
samples.loc[samples.index.isin(ASSEMBLED), "type"] = "assembled"
samples.loc[samples.index.isin(NANOPORE_SAMPLES), "type"] = "nanopore"
samples.loc[samples.index.isin(SRA_NANOPORE_SAMPLES), "type"] = "nanopore sra"
samples.loc[samples.index.isin(ILLUMINA_SAMPLES), "type"] = "illumina"
samples.loc[samples.index.isin(SRA_ILLUMINA_SAMPLES), "type"] = "illumina sra"


def get_nanopore_file(wildcards):
    """Return the source type ('nanopore' local or 'sra') for a Nanopore sample.
    Used with Snakemake's branch() to route inputs in filtlong and nanoplot rules.
    """
    sample = wildcards.sample
    if samples.loc[sample, "type"] == "nanopore":
        return "nanopore"
    elif samples.loc[sample, "type"] == "nanopore sra":
        return "sra"


def qc_report():
    """
    Return the MultiQC report path ONLY if explicitly requested.
    Currently disabled (returns []) so that downstream all_* rules
    do NOT auto-trigger the full QC chain. To get the QC report, run:
        snakemake all_qc --use-conda
    To re-enable auto-triggering, restore the body:
        if len(ALL_ILLUMINA_SAMPLES) > 0 or len(ALL_NANOPORE_SAMPLES) > 0:
            return ["results/multiqc_report.html"]
    """
    return []

