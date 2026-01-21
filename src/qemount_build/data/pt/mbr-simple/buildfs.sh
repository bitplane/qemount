#!/bin/sh
# $1 = input directory (unused for partition tables)
# $2 = output file
set -e

FAT16=/host/build/data/fs/basic.fat16
FAT32=/host/build/data/fs/basic.fat32

# Get actual sizes in bytes
FAT16_SIZE=$(stat -c %s "$FAT16")
FAT32_SIZE=$(stat -c %s "$FAT32")

# Convert to sectors (512 bytes each), round up
FAT16_SECTORS=$(( (FAT16_SIZE + 511) / 512 ))
FAT32_SECTORS=$(( (FAT32_SIZE + 511) / 512 ))

# Partition 1 starts at sector 2048 (1MB alignment)
P1_START=2048
P1_SIZE=$FAT16_SECTORS

# Partition 2 starts after partition 1
P2_START=$(( P1_START + P1_SIZE ))
P2_SIZE=$FAT32_SECTORS

# Total disk size in bytes (add 1MB at start + both partitions + 1MB padding)
TOTAL_SECTORS=$(( P2_START + P2_SIZE + 2048 ))
TOTAL_BYTES=$(( TOTAL_SECTORS * 512 ))

truncate -s "$TOTAL_BYTES" "$2"

sfdisk "$2" << EOF
label: dos
start=$P1_START, size=$P1_SIZE, type=6
start=$P2_START, size=$P2_SIZE, type=b
EOF

# Copy filesystem images into partitions
dd if="$FAT16" of="$2" bs=512 seek=$P1_START conv=notrunc status=none
dd if="$FAT32" of="$2" bs=512 seek=$P2_START conv=notrunc status=none
