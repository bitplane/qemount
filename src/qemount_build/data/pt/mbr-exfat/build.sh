#!/bin/sh
# $1 = output file (relative path, e.g. data/pt/exfat.mbr)
set -eu

OUTPUT="/host/build/$1"
EXFAT=/host/build/data/fs/basic.exfat
START=2048
EXFAT_BYTES=$(stat -c %s "$EXFAT")
SIZE=$((EXFAT_BYTES / 512))
TOTAL_SECTORS=$((START + SIZE + 2048))

if [ $((EXFAT_BYTES % 512)) -ne 0 ]; then
    echo "Filesystem fixture is not sector-aligned" >&2
    exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"
truncate -s $((TOTAL_SECTORS * 512)) "$OUTPUT"

sfdisk "$OUTPUT" << EOF
label: dos
start=$START, size=$SIZE, type=7
EOF

dd if="$EXFAT" of="$OUTPUT" bs=512 seek=$START conv=notrunc status=none
dd if="$OUTPUT" bs=512 skip=$START count=$SIZE status=none | cmp - "$EXFAT"
