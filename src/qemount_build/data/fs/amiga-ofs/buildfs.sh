#!/bin/sh
# $1 = input directory
# $2 = output file
set -e

# Create 10MB HDF and format as OFS (needs .hdf extension)
xdftool /tmp/output.hdf create size=10M + format TestFS ofs

# Write each item from template to root of image
cd "$1"
for item in *; do
    xdftool /tmp/output.hdf write "$item"
done

cp /tmp/output.hdf "$2"
