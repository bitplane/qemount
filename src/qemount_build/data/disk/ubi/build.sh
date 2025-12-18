#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .ubi)
UBIFS_PATH="/host/build/tests/data/fs/${BASE_NAME}.ubifs"

# Create ubinize config pointing to pre-built UBIFS image
cat > /tmp/ubinize.cfg << EOF
[rootfs]
mode=ubi
image=${UBIFS_PATH}
vol_id=0
vol_size=64MiB
vol_type=dynamic
vol_name=rootfs
vol_flags=autoresize
EOF

# Create UBI image
# -m: minimum I/O unit (page size)
# -p: physical erase block size
# -s: sub-page size (usually same as min I/O for MLC NAND)
ubinize -o /tmp/output.ubi -m 2048 -p 128KiB -s 2048 /tmp/ubinize.cfg

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.ubi "/host/build/$OUTPUT_PATH"
