#!/bin/sh
# $1 = output file (relative path, e.g. data/pt/basic.mbr)
set -e

OUTPUT="/host/build/$1"
mkdir -p "$(dirname "$OUTPUT")"

FAT12=/host/build/data/fs/basic.fat12
FAT16=/host/build/data/fs/basic.fat16
FAT32=/host/build/data/fs/basic.fat32

# Get actual sizes in bytes
FAT12_SIZE=$(stat -c %s "$FAT12")
FAT16_SIZE=$(stat -c %s "$FAT16")
FAT32_SIZE=$(stat -c %s "$FAT32")

for size in "$FAT12_SIZE" "$FAT16_SIZE" "$FAT32_SIZE"; do
    if [ $((size % 512)) -ne 0 ]; then
        echo "Filesystem fixture is not sector-aligned: $size bytes" >&2
        exit 1
    fi
done

# Convert to sectors (512 bytes each), round up
FAT12_SECTORS=$(( (FAT12_SIZE + 511) / 512 ))
FAT16_SECTORS=$(( (FAT16_SIZE + 511) / 512 ))
FAT32_SECTORS=$(( (FAT32_SIZE + 511) / 512 ))

# Partition 1 starts at sector 2048 (1MB alignment)
P1_START=2048
P1_SIZE=$FAT12_SECTORS

# Subsequent filesystem images are already sector-aligned.
P2_START=$(( P1_START + P1_SIZE ))
P2_SIZE=$FAT16_SECTORS
P3_START=$(( P2_START + P2_SIZE ))
P3_SIZE=$FAT32_SECTORS

# Add 1 MiB of trailing padding.
TOTAL_SECTORS=$(( P3_START + P3_SIZE + 2048 ))
TOTAL_BYTES=$(( TOTAL_SECTORS * 512 ))

rm -f "$OUTPUT"
truncate -s "$TOTAL_BYTES" "$OUTPUT"

sfdisk "$OUTPUT" << EOF
label: dos
start=$P1_START, size=$P1_SIZE, type=1
start=$P2_START, size=$P2_SIZE, type=6
start=$P3_START, size=$P3_SIZE, type=b
EOF

# Copy filesystem images into partitions
dd if="$FAT12" of="$OUTPUT" bs=512 seek=$P1_START conv=notrunc status=none
dd if="$FAT16" of="$OUTPUT" bs=512 seek=$P2_START conv=notrunc status=none
dd if="$FAT32" of="$OUTPUT" bs=512 seek=$P3_START conv=notrunc status=none

# Verify that partition construction did not alter or truncate any fixture.
dd if="$OUTPUT" bs=512 skip=$P1_START count=$P1_SIZE status=none |
    cmp - "$FAT12"
dd if="$OUTPUT" bs=512 skip=$P2_START count=$P2_SIZE status=none |
    cmp - "$FAT16"
dd if="$OUTPUT" bs=512 skip=$P3_START count=$P3_SIZE status=none |
    cmp - "$FAT32"
