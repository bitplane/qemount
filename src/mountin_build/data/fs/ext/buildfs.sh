#!/bin/sh
# $1 = input directory
# $2 = output file

# Note: mkfs.ext creates the file, no need for truncate
mkfs.ext -d "$1" "$2" 10
