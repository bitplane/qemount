#!/bin/sh
# $1 = input directory
# $2 = output file
# UBIFS params for simulated 128MB NAND:
# -m: min I/O unit (page size, 2048 for NAND)
# -e: logical erase block size (PEB - 2 pages overhead)
# -c: max LEB count
# -F: free space fix-up
mkfs.ubifs -r "$1" -o "$2" -m 2048 -e 126976 -c 1024 -F
