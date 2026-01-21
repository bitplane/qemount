#!/bin/sh
# $1 = output file (relative path, e.g. data/pt/extended.mbr)
set -e

OUTPUT="/host/build/$1"
mkdir -p "$(dirname "$OUTPUT")"

FAT16=/host/build/data/fs/basic.fat16
FAT32=/host/build/data/fs/basic.fat32
EXT4=/host/build/data/fs/basic.ext4

# Get actual sizes in bytes
FAT16_SIZE=$(stat -c %s "$FAT16")
FAT32_SIZE=$(stat -c %s "$FAT32")
EXT4_SIZE=$(stat -c %s "$EXT4")

# Convert to sectors (512 bytes each)
FAT16_SECTORS=$(( (FAT16_SIZE + 511) / 512 ))
FAT32_SECTORS=$(( (FAT32_SIZE + 511) / 512 ))
EXT4_SECTORS=$(( (EXT4_SIZE + 511) / 512 ))

# Layout:
# - Partition 1 (primary FAT16): starts at 2048
# - Partition 2 (extended): starts after P1, contains all logicals
#   - Logical 5 (FAT32): starts 2048 sectors into extended (for EBR + alignment)
#   - Logical 6 (ext4): starts after logical 5

P1_START=2048
P1_SIZE=$FAT16_SECTORS

# Extended partition starts after primary
EXT_START=$(( P1_START + P1_SIZE ))

# Logical partitions need space for EBR (we use 2048 sector alignment)
# Logical 5 data starts at EXT_START + 2048
L5_DATA_START=$(( EXT_START + 2048 ))
L5_SIZE=$FAT32_SECTORS

# Logical 6 data starts after L5 + another EBR gap
L6_DATA_START=$(( L5_DATA_START + L5_SIZE + 2048 ))
L6_SIZE=$EXT4_SECTORS

# Extended partition must contain all logicals
EXT_END=$(( L6_DATA_START + L6_SIZE ))
EXT_SIZE=$(( EXT_END - EXT_START ))

# Total disk size
TOTAL_SECTORS=$(( EXT_END + 2048 ))
TOTAL_BYTES=$(( TOTAL_SECTORS * 512 ))

truncate -s "$TOTAL_BYTES" "$OUTPUT"

# sfdisk handles EBR creation for logical partitions automatically
sfdisk "$OUTPUT" << EOF
label: dos
start=$P1_START, size=$P1_SIZE, type=6
start=$EXT_START, size=$EXT_SIZE, type=5
start=$L5_DATA_START, size=$L5_SIZE, type=b
start=$L6_DATA_START, size=$L6_SIZE, type=83
EOF

# Copy filesystem images into partitions
dd if="$FAT16" of="$OUTPUT" bs=512 seek=$P1_START conv=notrunc status=none
dd if="$FAT32" of="$OUTPUT" bs=512 seek=$L5_DATA_START conv=notrunc status=none
dd if="$EXT4" of="$OUTPUT" bs=512 seek=$L6_DATA_START conv=notrunc status=none
