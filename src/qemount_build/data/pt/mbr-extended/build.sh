#!/bin/sh
# $1 = output file (relative path, e.g. data/pt/extended.mbr)
set -e

OUTPUT="/host/build/$1"
mkdir -p "$(dirname "$OUTPUT")"

# Filesystem images
FAT16=/host/build/data/fs/basic.fat16
FAT32=/host/build/data/fs/basic.fat32
EXT2=/host/build/data/fs/basic.ext2
EXT3=/host/build/data/fs/basic.ext3
EXT4=/host/build/data/fs/basic.ext4
XFS=/host/build/data/fs/basic.xfs

# Get sizes in sectors (512 bytes each), rounded up
sectors() { echo $(( ($(stat -c %s "$1") + 511) / 512 )); }

FAT16_SECTORS=$(sectors "$FAT16")
FAT32_SECTORS=$(sectors "$FAT32")
EXT2_SECTORS=$(sectors "$EXT2")
EXT3_SECTORS=$(sectors "$EXT3")
EXT4_SECTORS=$(sectors "$EXT4")
XFS_SECTORS=$(sectors "$XFS")

# Layout:
# - Partition 0 (primary FAT16): starts at 2048
# - Partition 1 (extended): starts after P0, contains all logicals
#   - Logical 4 (FAT32): 2048 sector gap for EBR
#   - Logical 5 (ext2): 2048 sector gap for EBR
#   - Logical 6 (ext3): 2048 sector gap for EBR
#   - Logical 7 (ext4): 2048 sector gap for EBR
#   - Logical 8 (xfs): 2048 sector gap for EBR

EBR_GAP=2048

P0_START=2048
P0_SIZE=$FAT16_SECTORS

# Extended partition starts after primary
EXT_START=$(( P0_START + P0_SIZE ))

# Logical partitions (each needs EBR gap before data)
L4_START=$(( EXT_START + EBR_GAP ))
L4_SIZE=$FAT32_SECTORS

L5_START=$(( L4_START + L4_SIZE + EBR_GAP ))
L5_SIZE=$EXT2_SECTORS

L6_START=$(( L5_START + L5_SIZE + EBR_GAP ))
L6_SIZE=$EXT3_SECTORS

L7_START=$(( L6_START + L6_SIZE + EBR_GAP ))
L7_SIZE=$EXT4_SECTORS

L8_START=$(( L7_START + L7_SIZE + EBR_GAP ))
L8_SIZE=$XFS_SECTORS

# Extended partition must contain all logicals
EXT_END=$(( L8_START + L8_SIZE ))
EXT_SIZE=$(( EXT_END - EXT_START ))

# Total disk size
TOTAL_SECTORS=$(( EXT_END + 2048 ))
TOTAL_BYTES=$(( TOTAL_SECTORS * 512 ))

truncate -s "$TOTAL_BYTES" "$OUTPUT"

# sfdisk handles EBR creation for logical partitions automatically
sfdisk "$OUTPUT" << EOF
label: dos
start=$P0_START, size=$P0_SIZE, type=6
start=$EXT_START, size=$EXT_SIZE, type=5
start=$L4_START, size=$L4_SIZE, type=b
start=$L5_START, size=$L5_SIZE, type=83
start=$L6_START, size=$L6_SIZE, type=83
start=$L7_START, size=$L7_SIZE, type=83
start=$L8_START, size=$L8_SIZE, type=83
EOF

# Copy filesystem images into partitions
dd if="$FAT16" of="$OUTPUT" bs=512 seek=$P0_START conv=notrunc status=none
dd if="$FAT32" of="$OUTPUT" bs=512 seek=$L4_START conv=notrunc status=none
dd if="$EXT2" of="$OUTPUT" bs=512 seek=$L5_START conv=notrunc status=none
dd if="$EXT3" of="$OUTPUT" bs=512 seek=$L6_START conv=notrunc status=none
dd if="$EXT4" of="$OUTPUT" bs=512 seek=$L7_START conv=notrunc status=none
dd if="$XFS" of="$OUTPUT" bs=512 seek=$L8_START conv=notrunc status=none
