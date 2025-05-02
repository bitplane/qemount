#!/bin/bash
# Creates an ISO9660 image from a directory
set -eo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source_dir> <output.iso>"
    exit 1
fi

SRC_DIR="$1"
OUTPUT="$2"
OUTDIR=$(dirname "$OUTPUT")

# Create output directory if needed
mkdir -p "$OUTDIR"

# Create ISO image
if command -v genisoimage &>/dev/null; then
    genisoimage -r -J -o "$OUTPUT" "$SRC_DIR"
elif command -v mkisofs &>/dev/null; then
    mkisofs -r -J -o "$OUTPUT" "$SRC_DIR"
else
    echo "Error: Need genisoimage or mkisofs"
    exit 1
fi

echo "Created ISO: $OUTPUT"