#!/bin/sh
set -e

# Loop over all outputs in META.provides
for output in $(echo "$META" | jq -r '.provides | keys[]'); do
    # Extract base name (strip path and extension)
    base_name=$(basename "$output" | sed 's/\.[^.]*$//')
    ubifs_path="/host/build/data/fs/${base_name}.ubifs"

    # Create ubinize config pointing to pre-built UBIFS image
    cat > /tmp/ubinize.cfg << EOF
[rootfs]
mode=ubi
image=${ubifs_path}
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
    output_path="/host/build/$output"
    mkdir -p "$(dirname "$output_path")"
    ubinize -o "$output_path" -m 2048 -p 128KiB -s 2048 /tmp/ubinize.cfg

    echo "Built: $output"
done
