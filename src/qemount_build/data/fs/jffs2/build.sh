#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .jffs2)
TAR_PATH="/host/build/tests/data/templates/${BASE_NAME}.tar"

mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

# Create JFFS2 image with 128KB erase blocks (common for NOR flash)
# -n: don't add cleanmarkers (for raw images without OOB)
# -e: erase block size
# -p: pad to next erase block boundary
mkfs.jffs2 -d /tmp/template -o /tmp/output.jffs2 -e 128KiB -n -p

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.jffs2 "/host/build/$OUTPUT_PATH"
