import os

directory = input("Path to folder containing raw files (e.g. data/raw/) : ")

output_file = "config/samplesheet.tsv"

with open(output_file, "w") as out:
    out.write("ID\tR1\tR2\n")
    for filename in os.listdir(directory):
        if "_R1" in filename and filename.endswith(".fastq.gz"):
            r1_file = os.path.join(directory, filename)
            r2_filename = filename.replace("_R1", "_R2", 1)
            r2_file = os.path.join(directory, r2_filename)
            id_split = filename.split("_R1")[0]
            out.write(f"{id_split}\t{r1_file}\t{r2_file}\n")

print(f"The sample sheet has been created in {output_file}.\nPlease check that the information is correct, otherwise you can manually modify the file or regenerate this script.")
