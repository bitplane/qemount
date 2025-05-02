#!/bin/bash
# Creates an uncompressed tar archive from a directory
set -eo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source_dir> <output.tar>"
    exit 1
fi

SRC_DIR="$1"
OUTPUT="$2"
OUTDIR=$(dirname "$OUTPUT")

# Create output directory if needed
mkdir -p "$OUTDIR"

# Create tar archive
tar -cf "$OUTPUT" -C "$SRC_DIR" .

echo "Created tar archive: $OUTPUT"