import yaml
#from Levenshtein import distance
import levenshtein2 as le
import subprocess
import tempfile
import json
from io import StringIO
from zipfile import ZipFile
import shutil
import os
from Bio import SeqIO

def ask(quest):
    respon = ''
    while respon != 'y' and respon != 'n':
        respon = input(quest + " [y/n] ")
    if respon == 'y':
        return True
    return False

def ask_path(quest, fi=True, wait=""):
    respon = ''
    while respon == '' and os.path.exists(respon) is False:
        respon = input(quest + " [path] ")
        if fi:
            if os.path.isdir(respon) or respon.endswith(wait) is False:
                info("You must select an file finishing by", wait)
                respon = ''
        else:
            if os.path.isfile(respon):
                info("You must select an folder containing the database")
                respon = ''
                
    return respon

def info(infor, value = ''):
    if value == '':
        print( infor + "\n")
    else:
        print( infor + " : " + value + "\n")

##Config file
with open("config/config.example.yml", "r") as file:
    config = yaml.safe_load(file)
info("Load config file", "ok")
    
with open("config/amrfinder_species.yml", "r") as file:
    species_data = yaml.safe_load(file)
amrfinder_species = species_data["amrfinder_species"]
info("Load AMRFinder species list", "ok")

##species validation
species = input("Please indicate the full name of your species: ")

info("Validate species on NCBI taxonomy")
taxo = subprocess.run(["datasets", "summary", "taxonomy", "taxon", species], capture_output=True, text=True)
if taxo.stderr == '':
    taxo = json.load(StringIO(taxo.stdout))
    count = taxo.get("total_count")
    if count != 1:
        info("No correct species found")
    info("Number of species found", str(count))
    try:
        taxid = taxo.get('reports')[0].get('taxonomy').get('tax_id')
        info("Species taxid found", str(taxid))
    except:
        info("Taxid not found", "skip reference download")
        taxid = None
else:
    info("Error during taxonomy check", "\n" +  taxo.stderr)
    exit()

reference = False
if taxid and ask("Do you want to download reference genome"):
    tmp = tempfile.TemporaryDirectory()
    tmpfi = tmp.name + "/" + "ncbi_dataset.zip"
    data = subprocess.run(["datasets", "download", "genome", "taxon", str(taxid), "--include",
                           "genome", "--reference", "--filename", tmpfi, "--no-progressbar"],
                          capture_output=True, text=True)
    if data.stderr != '':
        info("Error during reference download", "\n" + data.stderr)
        shutil.rmtree(tmp.name)
        exit()

    zip = ZipFile(tmpfi, 'r')
    seqs = [i for i in zip.namelist() if i.endswith("fna")]
    if len(seqs) == 0:
        print("Found no reference genome")
    else:
        extr = zip.extract(seqs[0], tmp.name)
        ref = config['configuration']['reference']
        os.makedirs(os.path.dirname(ref), exist_ok=True)
        shutil.move(extr, ref)
        reference = True
    shutil.rmtree(tmp.name)


##Genome size
if reference:
    genome_size = 0
    for seq in SeqIO.parse(config['configuration']['reference'], 'fasta'):
        genome_size += len(seq.seq)
else:
    genome_size = input("Please indicate the size of the genome in bp: ")
    genome_size = int(genome_size)

info("The genome size was in bp", str(genome_size))


##AMRFinder
best_species = ''

if ask("Would you like to specify a species for AMRFinder analysis ?"):
    for name in amrfinder_species:
        if le.diff_less_than_nogap(species, name, 3):
            best_species = name
    if best_species == '':
        info("No species found for AMRFinder analysis")
    else:
        info("Species selected for AMRFinder analysis", best_species)


##Plasmid
plasmid_tool = ''
if ask("Would you like to use a plasmid analysis tool ?"):
    tmp = []
    if ask("Do you want to use Platon?"):
        tmp.append("platon")
    if ask("Do you want to use Plasclass?"):
        tmp.append("plasclass")
    plasmid_tool = ",".join(tmp)
    info("Plasmid tool selected", plasmid_tool)
else:
    info("No plasmid analysis tools used.")


info("Database configuration")
if ask("Do you have already installed kraken database?"):
    kraken = ask_path("Select kraken database folder", fi=False)
    config['configuration']['kraken_db_path'] = kraken
if ask("Do you have already installed CheckM2 database?"):
    checkm2 = ask_path("Select CheckM2 file .dmnd", wait="dmnd")
    config['configuration']['checkm2_db'] = checkm2
if ask("Do you have already installed Platon database?"):
    platon = ask_path("Select Platon database folder", fi=False)
    config['configuration']['platon_db'] = platon


info("Creation of the config file ...")
config['configuration']['species'] = species
config['configuration']['genome_size'] = genome_size
config['configuration']['plasmid_tool'] = plasmid_tool
config['amrfinder']['species'] = best_species

config_file = "config/config.yml"
with open(config_file, "w") as file:
    yaml.dump(config, file, default_flow_style=False, sort_keys=False, allow_unicode=True)

info(f"The configuration file has been created in {config_file}.\nPlease check that the information is correct, otherwise you can manually modify the file or regenerate this script.")

