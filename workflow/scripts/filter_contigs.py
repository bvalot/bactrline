import os
from Bio import SeqIO

def read_flye_info(info_file):
    contig_info = {}
    with open(info_file, 'r') as infofile:
        for line in infofile:
            if line.startswith('contig'):
                parts = line.strip().split('\t')
                name = parts[0]
                length = int(parts[1])
                cov = float(parts[2])
                contig_info[name] = {'length': length, 'cov': cov}
    return(contig_info)

with open(snakemake.log[0], "w") as f:
    sys.stderr = sys.stdout = f
    min_length = snakemake.params.len_contig
    min_coverage = snakemake.params.cov_contig

    contig_info = None
    if os.path.exists(snakemake.params.info_file):
        contig_info = read_flye_info(snakemake.params.info_file)

    with open(snakemake.output.filtered_contigs_file, 'w') as outfile:
        for seq in SeqIO.parse(snakemake.input.contigs_file, 'fasta'):
            if contig_info:
                info = contig_info.get(seq.id, None)
                if info:
                    if info['length'] >= min_length and info['cov'] >= min_coverage:
                        SeqIO.write(seq, outfile, 'fasta')
                else:
                    sys.stderr.write("ERROR contig not found on contig_info: " + seq.id + "\n")
                    if len(seq.seq) >= min_length:
                        SeqIO.write(seq, outfile, 'fasta')
            else:
                try:
                    length_cov_info = seq.id.split('_length_')[1].split('_cov_')
                    length = int(length_cov_info[0])
                    cov = float(length_cov_info[1])
                    if length >= min_length and cov >= min_coverage:
                        SeqIO.write(seq, outfile, 'fasta')
                except:
                    sys.stderr.write("ERROR parsing coverage on id: " + seq.id + "\n")
                    if len(seq.seq) >= min_length:
                        SeqIO.write(seq, outfile, 'fasta')
