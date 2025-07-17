# bactRline : Pipeline for bacterial genomes assembly and characterization

## Contents

### Summary

**bactRline** is a Snakemake-based workflow for the assembly and characterization of bacterial genomes from whole-genome sequencing (WGS) data. It automates the processing of raw sequencing reads through quality control, assembly, and annotation steps.
We have provided a step-by-step description of how to set up the working environment and the configuration to run it. We recommend that you read the instructions below carefully to obtain the desired results. \

Tools Used:
  * Pre-processing: TrimGalore, Filtlong
  * Genome assembly: SPAdes, Flye
  * Quality evaluation: QUAST, Kraken2, CheckM2
  * Annotation and typing: AMRFinderPlus, pyMLST
  * (Optional) Plasmid detection: Platon, PlasClass

The workflow accepts the following input formats:
  * Illumina: paired-end reads in `.fastq.gz` format
  * Oxford Nanopore: reads in `.fastq.gz` format
  * SRA: `.sra` files or accession numbers (e.g., SRRxxxxxxx)


### Installation

#### 1. Installation of Mamba

We recommend using a Mamba environment to run the pipeline.

* Download the mambaforge according to your operating system (Linux, macOS, or Windows)
  * https://github.com/conda-forge/miniforge#mambaforge

* Install mambaforge :
  * open a terminal
  * navigate to the directory where the installer was download
  * run this command:

```
curl -L -O https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
bash Miniforge3-Linux-x86_64.sh
mamba --version
```


#### 2. Installation of Snakemake

```
git clone https://github.com/bvalot/bactrline.git
cd bactrline
mamba create -f workflow/envs/default.yml
mamba activate bactRline
snakemake --help
```

By default, Snakemake generates its environments in a folder local to your project `.snakemake/conda/`. If you plan to have several projects, you can use the following option `--conda-prefix /path/to/conda_envs/` to generate or use environments in a folder of your choice.
You can also defined it as default in your bactrline environment:

```
SNAKEMAKE_CONDA_PREFIX=/path/to/env
conda env config vars set SNAKEMAKE_CONDA_PREFIX=$SNAKEMAKE_CONDA_PREFIX
```


#### 3. Configuration

Snakemake needs a configuration file to run. \
You can generate it with the following script `workflow/scripts/configuration.py`, or you can write it manually in `config/config.yml` using the example in `config/config.example.yml`. \
The configuration file must include the following key sections:

```
configuration:
  genome_size: 2800000                   # Estimated genome size in bp
  species: 'Staphylococcus aureus'       # Name of the species
  plasmid_tool: 'platon,plasclass'       # Plasmid detection tools to use : 'platon', 'plasclass', both ('platon,plasclass') or leave empty
```

> Important: If you are analyzing data from *E. coli* or *S. aureus*, make sure to use the correct formatting in the species field: 'Escherichia coli' or 'Staphylococcus aureus'.

```
resources:
  threads: 6       # Number of CPU threads to use
  mem_mb: 10000    # Maximum memory in megabytes to allocate per job
```

> Adjust these values based on the resources in your system.

```
amrfinder:
  species: 'Staphylococcus_aureus'       # Species identifier used by AMRFinderPlus
```

> Note: You can find the list of valid species identifiers for AMRFinderPlus in `config/amrfinder_species.yml`. If your species is not listed there, you should leave this field empty.

\
Moreover, the pipeline requires several sample sheets, depending on the sequencing technology and data source:
  * `config/sample_illumina.tsv`: for paired-end Illumina data. It contain the sample ID and the path to the data raw (R1 and R2) like in the example `config/sample_illumina.example.tsv`.
  * `config/sample_nanopore.tsv`: for Oxford Nanopore data. It contain the sample ID and the path to the folder or file that contains the raw reads, like in example `config/sample_nanopore.example.tsv`.
  * `config/sra.tsv`: for SRA data. It contain the sample ID, the sequencing technology used (`illumina` or `nanopore`), and the path to the `.sra` file or the SRR run ID.
  * `config/samplesheet.tsv`: this file is always required. It contain only the sample ID to be used in the workflow.

You can generate these files manually or use the script `workflow/scripts/samplesheet.py` to generate them. \
Please, if you use a script in both cases, check the output files `config/config.yml` and `config/samplesheet.tsv`.

For the pipeline, you need to provide a reference genome. You can place it in a `resources/reference/` directory, but please change the path in the configuration file.


#### 4. Configuration file option

You can change the resources maximal that can be used by certain rules with `threads` : the number of threads, and `mem_mb` : RAM in MB. \
You can add any parameters you like to `extra_params` for each tool.
> We recommend using the `--memory-mapping` option for Kraken2 if you have 16GB RAM or less.


#### 5. Installation of databases

The Kraken2, CheckM2, AMRFinderPlus, pyMLST and Platon tools require a database to run. If you already have the database, you can simply enter the path in the configuration file. Otherwise, you can use the following commands to install one database at a time:

```
snakemake install_amrfinder_db --use-conda      # To initiallise AMRFinderPlus database
snakemake install_pymlst_db --use-conda         # To install pyMLST database
snakemake install_checkm2_db --use-conda        # To install CheckM2 database
```

You can download the Kraken2 and Platon databases manually by following the steps below:

```
# Kraken2 database
wget -P resources/database https://genome-idx.s3.amazonaws.com/kraken/k2_standard_16gb_20250402.tar.gz
mkdir -p resources/database/k2_standard_16gb_20250402
tar -xzf resources/database/k2_standard_16gb_20250402.tar.gz -C resources/database/k2_standard_16gb_20250402
rm resources/database/k2_standard_16gb_20250402.tar.gz
```

```
# Platon database
wget -P resources/database/platon https://zenodo.org/record/4066768/files/db.tar.gz
tar -xzf resources/database/platon/db.tar.gz -C resources/database/platon/
rm resources/database/platon/db.tar.gz
```

Please check that the path in the configuration file corresponds to the database path.


##### 6. Installation of conda environnements

You can install conda environment before running the pipeline:

```
snakemake --conda-create-envs-only --use-conda
```

> Note: This step could take some times!!!


### Usage

Before running the pipeline, you can check that everything is working correctly using `--dry-run option`:

```
snakemake --use-conda --dry-run
```

This will simulate the workflow without executing any commands.

Then, from the cloned Git repository, run the pipeline with the folowing command :

```
snakemake --use-conda
```

If you want to run only the assembly part, for example, you can run this command:

```
snakemake all_assembly --use-conda
```


### Test

To avoid errors, particularly during the first run to initialize the pyMLST database, and to check that the configuration file is correctly configured, you can run the pipeline with a single sample.


### Output Files

The pipeline gives three final reports, which you can find in the `workflow/reports/` directory.

#### Quality report

|         Column         |                          Description                         |
| ---------------------- | ------------------------------------------------------------ |
| Sample                 | ID of the sample                                             |
| Contigs                | Number of contigs in the assembly                            |
| Total length           | Total length of the assembly                                 |
| Largest contig         | Length of the largest contig                                 |
| GC (%)                 | Percentage of G and C nucleotides in the assembly            |
| N50                    | Shortest contig length required to cover 50% of the assembly |
| L50                    | Minimum number of contigs covering 50% of the assembly       |
| Major Genus            | The majority genus found                                     |
| Major Genus (%)        | Percent of the majority genus                                |
| Major Species          | The majority species found                                   |
| Major Species (%)      | Percent of the majority species                              |
| Other Genus            | Other genus found >1%                                        |
| Other Species          | Other species found >1%                                      |
| Reference length       | Length of the reference given                                |
| Reference GC (%)       | Percent of G and C nucleotides in the reference given        |
| Completeness           | Completeness of the assembly                                 |
| Contamination          | Contamination of the assembly                                |
| Quality validation     | Indicator of potential contamination                         |
| Problematic parameters | Metrics that cause the potential contamination               |


#### Annotation report

| Column    | Description                    |
|-----------|--------------------------------|
| Sample    | ID of the sample               |
| MLST      | Sequence Type (ST) and alleles |
| AMR       | Antimicrobial resistance gene  |
| Stress    | Stress response                |
| Virulence | Virulence factors              |


#### Gene Summary

| Column              | Description                                                                         |
|---------------------|-------------------------------------------------------------------------------------|
| Element symbol      | Symbol of the gene                                                                  |
| Element name        | Complete name of the gene                                                           |
| Type                | Type of the gene (AMR, STRESS, or VIRULENCE)                                        |
| Subtype             | Subtype of the gene (AMR, POINT, ACID, BIOCIDE, ANTIGEN, HEAT, METAL, or VIRULENCE) |
| Class               | Phenotype affected by the gene                                                      |
| Subclass            | More specific classes that are affected by the gene                                 |
| Reference accession | Accession number of reference use to find gene                                      |


## Authors
- Adeline Gagnon
- Ana Temtem
- Benoit Valot

## Citation

## License
This program was licenced with the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 Copyright (C) 2007 Free Software Foundation, Inc.
