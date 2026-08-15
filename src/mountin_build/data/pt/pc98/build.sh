#!/bin/sh
# $1 = output file (e.g. data/pt/basic.pc98)
set -e

OUTPUT="/host/build/$1"
mkdir -p "$(dirname "$OUTPUT")"

FAT=/host/build/data/fs/basic.fat16
FAT_SIZE=$(stat -c %s "$FAT")

# PC-98 geometry: 8 heads, 16 sectors per track (parted's default)
HEADS=8
SPT=16
BYTES_PER_CYL=$((HEADS * SPT * 512))

# Round up to cylinder boundary
FAT_CYLS=$(( (FAT_SIZE + BYTES_PER_CYL - 1) / BYTES_PER_CYL ))

# Start at cylinder 1 (cylinder 0 reserved for boot/partition table)
START_CYL=1
TOTAL_CYLS=$((START_CYL + FAT_CYLS + 1))

truncate -s $((TOTAL_CYLS * BYTES_PER_CYL)) "$OUTPUT"

# Create PC-98 label with parted
parted -s "$OUTPUT" mklabel pc98

# Calculate sector positions
START_SECTOR=$((START_CYL * HEADS * SPT))
END_SECTOR=$((START_SECTOR + FAT_CYLS * HEADS * SPT - 1))

parted -s "$OUTPUT" mkpart primary fat16 ${START_SECTOR}s ${END_SECTOR}s

# Copy filesystem
dd if="$FAT" of="$OUTPUT" bs=512 seek=$START_SECTOR conv=notrunc status=none
