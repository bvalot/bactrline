#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""Return a subsampling fastq file"""

import argparse
import gzip
import io
import os
import random
import sys

import pysam

desc = "Subsampling a single or a paired of fastq(.gz) file"
command = argparse.ArgumentParser(
    prog="fastq_subsampling.py", description=desc, usage="%(prog)s [options] genomeSize"
)
command.add_argument("--galaxy", action="store_true", help=argparse.SUPPRESS)
command.add_argument(
    "-d",
    "--outdir",
    default="./",
    type=str,
    nargs="?",
    help="Directory to store subsampling fastq file, default: current directory",
)
command.add_argument(
    "-p",
    "--prefix",
    default="_sub",
    type=str,
    nargs="?",
    help="Output fastq file with prefix, default:_sub",
)
command.add_argument(
    "-c",
    "--coverage",
    type=int,
    nargs="?",
    default=60,
    help="Mean coverage to sampling (default=60)",
)
command.add_argument(
    "--copy",
    action="store_true",
    help="Perform a copy of sample without enough coverage (default=no subsampling)",
)
command.add_argument(
    "-s",
    "--sfastq",
    nargs="?",
    type=argparse.FileType("r"),
    help="Fastq(.gz) file to subsampling (single)",
)
command.add_argument(
    "-r",
    "--rfastq",
    nargs="?",
    type=argparse.FileType("r"),
    help="Fastq(.gz) file to subsampling in paired (right)", #right veut dire le bon sens == Forward R1 mais dans tous les cas ça change rien
)
command.add_argument(
    "-l",
    "--lfastq",
    nargs="?",
    type=argparse.FileType("r"),
    help="Fastq(.gz) file to subsampling in paired (left)", #left veut dire l'antisens ou sens inverse == Reverse R2
)
command.add_argument(
    "genomesize",
    type=int,
    help="Size of the genome (bp) for calculation of subsampling",
)
command.add_argument("-v", "--version", action="version", version="%(prog)s 0.2.0")


def outname(inname, outdir, append):
    inname = outdir + inname.split("/")[-1]
    if isgzip(inname):
        if inname[-5:] == "fq.gz":
            return inname.rstrip(".fq.gz") + append + ".fastq.gz"
        elif inname[-8:] == "fastq.gz":
            return inname.rstrip(".fastq.gz") + append + ".fastq.gz"
        else:
            return inname + append + ".fastq.gz"
    elif inname[-2:] == "fq":
        return inname.rstrip(".fq") + append + ".fastq.gz"
    elif inname[-5:] == "fastq":
        return inname.rstrip(".fastq") + append + ".fastq.gz"
    else:
        return inname + append + ".fastq.gz"


def isgzip(filename):
    if filename[-2:] == "gz":
        return True
    else:
        return False


def complet_count(fastq):
    count = 0
    total = 0.0
    for read in pysam.FastxFile(fastq):
        count += 1
        total += len(read.sequence)
    return count, int(total / count)


def make_copy(infile, outdir, prefix):
    output = outname(infile, outdir, prefix)
    os.popen(" ".join(["cp", infile, output]))


def make_subsampling(infile, outdir, prefix, select):
    output = io.BufferedWriter(gzip.open(outname(infile, outdir, prefix), "wb", 5)) # type: ignore
    for i, read in enumerate(pysam.FastxFile(infile)):
        if i in select:
            output.write((str(read) + "\n").encode())
    output.flush()
    output.close()


def make_subsampling_galaxy(infile, number, select):
    output = io.BufferedWriter(gzip.open("./" + str(number) + ".fastq.gz", "wb", 5)) # type: ignore
    for i, read in enumerate(pysam.FastxFile(infile)):
        if i in select:
            output.write((str(read) + "\n").encode())
    output.flush()
    output.close()


if __name__ == "__main__":
    """Performed job on execution script"""
    args = command.parse_args()

    # verify input
    if args.sfastq is None and args.lfastq is None and args.rfastq is None:
        raise Exception("At least single or paired reads must be defined")
    outdir = args.outdir
    if not os.path.isdir(outdir):
        raise Exception(outdir + " is not a valid directory")
    else:
        outdir = outdir.rstrip("/") + "/"

    # compute count and length
    fastqname = None
    if args.sfastq is not None:
        fastqname = args.sfastq.name
    elif args.rfastq is not None and args.lfastq is not None:
        fastqname = args.rfastq.name
    else:
        raise Exception("You must defined right and left fastq file for paired data")

    count = None
    length = None
    count, length = complet_count(fastqname)

    # Calculate coverage and report
    coverage = 0
    if args.sfastq is not None:
        coverage = int(float(count) * length / args.genomesize)
        print(
            " : ".join([fastqname, str(length) + "bp", str(count), str(coverage) + "X"])
        )
    else:
        coverage = int(float(count) * length * 2 / args.genomesize)
        print(
            " : ".join(
                [fastqname, str(length) + "bp*2", str(count), str(coverage) + "X"]
            )
        )

    # check coverage
    if coverage <= args.coverage:
        if args.copy and args.galaxy is False:
            if args.sfastq is not None:
                make_copy(args.sfastq.name, outdir, args.prefix)
            else:
                make_copy(args.rfastq.name, outdir, args.prefix)
                make_copy(args.lfastq.name, outdir, args.prefix)
        print("Coverage is less than threshold, no subsampling need")
        sys.exit(0)

    # performed subsampling
    if args.sfastq is not None:
        subread = int((float(args.genomesize) * args.coverage) / length)
        select = set(random.sample(range(0, count), subread))
        if args.galaxy:
            make_subsampling_galaxy(args.sfastq.name, 1, select)
        else:
            make_subsampling(args.sfastq.name, outdir, args.prefix, select)
        print("Subsampling to " + str(subread))
    else:
        subread = int((float(args.genomesize) * args.coverage) / (length * 2))
        select = set(random.sample(range(0, count), subread))
        if args.galaxy:
            make_subsampling_galaxy(args.rfastq.name, 1, select)
            make_subsampling_galaxy(args.lfastq.name, 2, select)
        else:
            make_subsampling(args.rfastq.name, outdir, args.prefix, select)
            make_subsampling(args.lfastq.name, outdir, args.prefix, select)
        print("Subsampling to " + str(subread))