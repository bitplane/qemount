#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .amiga-ffs)
TAR_PATH="/host/build/tests/data/templates/${BASE_NAME}.tar"

mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

# Create 10MB HDF image and format as FFS (needs .hdf extension)
xdftool /tmp/output.hdf create size=10M + format TestFS ffs

# Write each item from template to root of image
cd /tmp/template
for item in *; do
    xdftool /tmp/output.hdf write "$item"
done

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.hdf "/host/build/$OUTPUT_PATH"
