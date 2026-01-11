#!/bin/sh
# $1 = input directory
# $2 = output file
set -e

# Create 10MB HDF and format as OFS
xdftool "$2" create size=10M + format TestFS ofs

# Write each item from template to root of image
cd "$1"
for item in *; do
    xdftool "$2" write "$item"
done
