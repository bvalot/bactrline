import pandas as pd
from snakemake.utils import validate
import os

validate(config, "../schemas/config.schema.yml")

samples = pd.read_csv("config/samplesheet.tsv", sep="\t").set_index("ID", drop=False)
samples.index = samples.index.astype(str)
validate(samples, "../schemas/samples.schema.yml")

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

ILLUMINA_SAMPLES = [s for s in illumina.index if s in samples.index]
NANOPORE_SAMPLES = [s for s in nanopore.index if s in samples.index]
SRA_ILLUMINA_SAMPLES = [s for s in sra.index if s in samples.index and sra.loc[s, "tech"] == "illumina"]
SRA_NANOPORE_SAMPLES = [s for s in sra.index if s in samples.index and sra.loc[s, "tech"] == "nanopore"]
ALL_ILLUMINA_SAMPLES = set(ILLUMINA_SAMPLES + SRA_ILLUMINA_SAMPLES)
ALL_NANOPORE_SAMPLES = set(NANOPORE_SAMPLES + SRA_NANOPORE_SAMPLES)

