#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .ubifs)
TAR_PATH="/host/build/tests/data/templates/${BASE_NAME}.tar"

mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

# UBIFS parameters for simulated 128MB NAND:
# -m: minimum I/O unit size (page size, typically 2048 for NAND)
# -e: logical erase block size (PEB size minus 2 pages for UBI overhead)
#     For 128KB PEB with 2KB pages: 128K - 2*2K = 124KB = 126976
# -c: maximum LEB count (determines max filesystem size)
# -F: free space fix-up (allows mounting on empty UBI volume)
mkfs.ubifs -r /tmp/template -o /tmp/output.ubifs \
    -m 2048 -e 126976 -c 1024 -F

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.ubifs "/host/build/$OUTPUT_PATH"
