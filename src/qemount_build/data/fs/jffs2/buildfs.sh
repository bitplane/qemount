#!/bin/sh
# $1 = input directory
# $2 = output file
# -e: erase block size (128KB for NOR flash)
# -n: no cleanmarkers (for raw images without OOB)
# -p: pad to next erase block boundary
mkfs.jffs2 -d "$1" -o "$2" -e 128KiB -n -p
