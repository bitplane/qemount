#!/bin/bash
# Creates an ext2 filesystem image in userspace without root privileges
set -eo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source_dir> <output.ext2>"
    exit 1
fi

SRC_DIR="$1"
OUTPUT="$2"
OUTDIR=$(dirname "$OUTPUT")

# Create output directory if needed
mkdir -p "$OUTDIR"

# Calculate size needed (source size + 10% overhead, minimum 10MB)
SIZE=$(du -s -k "$SRC_DIR" | awk '{print int($1 * 1.1)}')
if [ $SIZE -lt 10240 ]; then
    SIZE=10240  # Minimum 10MB
fi

# Create the image file
echo "Creating $SIZE KB ext2 image..."
truncate -s ${SIZE}K "$OUTPUT"

# Format as ext2 using the -d option to directly populate from source directory
mke2fs -t ext2 -d "$SRC_DIR" "$OUTPUT"

echo "Created ext2 image: $OUTPUT"