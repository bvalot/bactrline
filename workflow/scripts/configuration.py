import yaml
from Levenshtein import distance

with open("config/config.example.yml", "r") as file:
    config = yaml.safe_load(file)
    
with open("config/amrfinder_species.yml", "r") as file:
    species_data = yaml.safe_load(file)
amrfinder_species = species_data["amrfinder_species"]

species = input("Please indicate the full name of your species: ")

d_ecoli = distance("Escherichia coli", species)
if ( 0 <= d_ecoli <= 6):
    ecoli = ''
    while ecoli != 'y' and ecoli != 'n': 
        ecoli = input("Is Escherichia coli ? [y/n] ")
    if ecoli == 'y':
        species = 'Escherichia coli'
        
d_staph = distance("Staphylococcus aureus", species)
if ( 0 <= d_staph <= 6):
    staph = ''
    while staph != 'y' and ecoli != 'n': 
        staph = input("Is Staphylococcus aureus ? [y/n] ")
    if staph == 'y':
        species = 'Staphylococcus aureus'

print("Your species selected: ", species)

print("\nSelect species for AMRFinder analysis... ")

best_species = None
min_distance = None

for name in amrfinder_species:
    d = distance(species, name)
    if min_distance == None or d < min_distance:
        min_distance = d
        best_species = name

max_threshold = 10

if min_distance <= max_threshold:
    print("Species find : ", best_species)
    good_species = ''
    while good_species != 'y' and good_species != 'n': 
        good_species = input("Is the good species ? [y/n] ")
    if good_species == 'y':
        print("Species selected for AMRFinder analysis: ", best_species)
    elif good_species == 'n':
        print(amrfinder_species, "\n")
        species_list = ''
        while species_list != 'y' and species_list != 'n':
            species_list = input("Is your species on this list ? [y/n] ")
        if species_list == 'y':
            best_species = ''
            while best_species not in amrfinder_species:
                best_species = input("\nPlease specify the exact name: ")
            print("Species selected for AMRFinder analysis : ", best_species)
        elif species_list == 'n':
            best_species = ''
            print("No species found for AMRFinder analysis.")
else:
    best_species = ''
    print("No species found for AMRFinder analysis.")


genome_size = input("\nPlease indicate the size of the genome: ")
genome_size = int(genome_size)
print("Your size selected: ", genome_size)

plasmid = ''
while plasmid != 'y' and plasmid != 'n':
    plasmid = input("\nWould you like to use a plasmid analysis tool ? [y/n] ")
if plasmid == 'y':
    plasmid_tool = ''
    while plasmid_tool != 'platon' and plasmid_tool != 'plasclass' and plasmid_tool != 'both':
        plasmid_tool = input("Do you want to use Platon, Plasclass or both ? [platon/plasclass/both] ")
    if plasmid_tool == 'both':
        plasmid_tool = 'platon,plasclass'
    print("Plasmid tool selected :", plasmid_tool)
elif plasmid == 'n':
    plasmid_tool = ''
    print("No plasmid analysis tools used.")

print("\nCreation of the config file ...")
config['configuration']['species'] = species
config['configuration']['genome_size'] = genome_size
config['configuration']['plasmid_tool'] = plasmid_tool
config['amrfinder']['species'] = best_species

config_file = "config/config.yml"
with open(config_file, "w") as file:
    yaml.dump(config, file, default_flow_style=False, sort_keys=False, allow_unicode=True)

print(f"The configuration file has been created in {config_file}.\nPlease check that the information is correct, otherwise you can manually modify the file or regenerate this script.")

