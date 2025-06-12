import os


def filter_contigs(input_file, output_file, min_coverage, min_length, info_file=None):
    contig_info = {}
    if info_file:
        with open(info_file, 'r') as infofile:
            for line in infofile:
                if line.startswith('contig'):
                    parts = line.strip().split('\t')
                    name = parts[0]
                    length = int(parts[1])
                    cov = float(parts[2])
                    contig_info[name] = {'length': length, 'cov': cov}
            
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        current_node = ""
        current_sequence = ""
        
        for line in infile:
            if line.startswith('>'):
                if current_node:
                    if contig_info:
                        if current_node in contig_info:
                            info = contig_info[current_node]
                            if info['length'] >= min_length and info['cov'] >= min_coverage:
                                outfile.write(f">{current_node}\n{current_sequence}\n")
                    else:
                        length_cov_info = current_node.split('_length_')[1].split('_cov_')
                        length = int(length_cov_info[0])
                        cov = float(length_cov_info[1])
                        if length >= min_length and cov >= min_coverage:
                            outfile.write(f">{current_node}\n{current_sequence}\n")
                current_node = line.strip()[1:]
                current_sequence = ""
            else:
                current_sequence += line.strip()
        if current_node:
            if contig_info:
                if current_node in contig_info:
                    info = contig_info[current_node]
                    if info['length'] >= min_length and info['cov'] >= min_coverage:
                        outfile.write(f">{current_node}\n{current_sequence}\n")
        else:
            length_cov_info = current_node.split('_length_')[1].split('_cov_')
            length = int(length_cov_info[0])
            cov = float(length_cov_info[1])
            if length >= min_length and cov >= min_coverage:
                outfile.write(f">{current_node}\n{current_sequence}\n")


filter_contigs(str(snakemake.input.contigs_file), str(snakemake.output), snakemake.params.cov_contig, snakemake.params.len_contig, str(snakemake.params.info_file) if os.path.exists(snakemake.params.info_file) else None)
