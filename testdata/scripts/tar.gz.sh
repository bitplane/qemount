#!/bin/bash
# Creates a compressed tar.gz archive from a directory
set -eo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source_dir> <output.tar.gz>"
    exit 1
fi

SRC_DIR="$1"
OUTPUT="$2"
OUTDIR=$(dirname "$OUTPUT")

# Create output directory if needed
mkdir -p "$OUTDIR"

# Create compressed tar archive
tar -czf "$OUTPUT" -C "$SRC_DIR" .

echo "Created tar.gz archive: $OUTPUT"