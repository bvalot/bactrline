import pandas as pd
import numpy as np
from snakemake.utils import validate
import os

validate(config, "../schemas/config.schema.yml")

# load table
samples = pd.read_csv("config/samplesheet.tsv", sep="\t").set_index("ID", drop=False)
samples.index = samples.index.astype(str)
validate(samples, "../schemas/samples.schema.yml")

if os.path.exists("config/genomes_assembled.tsv"):
    assembled = pd.read_csv("config/genomes_assembled.tsv", sep="\t").set_index("ID", drop=False)
else:
    assembled = pd.read_csv("config/genomes_assembled.example.tsv", sep="\t").set_index("ID", drop=False)
assembled.index = assembled.index.astype(str)
validate(assembled, "../schemas/genome.schema.yml")

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
ALL_ILLUMINA_SAMPLES = set(ILLUMINA_SAMPLES + SRA_ILLUMINA_SAMPLES)
ALL_NANOPORE_SAMPLES = set(NANOPORE_SAMPLES + SRA_NANOPORE_SAMPLES)
ASSEMBLED = samples.index.intersection(assembled.index)


samples["type"] = np.nan
samples.loc[samples.index.isin(ASSEMBLED), "type"] = "genome assembled"
samples.loc[samples.index.isin(NANOPORE_SAMPLES), "type"] = "nanopore"
samples.loc[samples.index.isin(SRA_NANOPORE_SAMPLES), "type"] = "nanopore sra"
samples.loc[samples.index.isin(ILLUMINA_SAMPLES), "type"] = "illumina"
samples.loc[samples.index.isin(SRA_ILLUMINA_SAMPLES), "type"] = "illumina sra"


