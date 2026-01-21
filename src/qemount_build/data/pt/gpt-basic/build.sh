#!/bin/sh
# $1 = output file (relative path, e.g. data/pt/basic.gpt)
set -e

OUTPUT="/host/build/$1"
mkdir -p "$(dirname "$OUTPUT")"

# Filesystem images
FAT32=/host/build/data/fs/basic.fat32
EXT2=/host/build/data/fs/basic.ext2
EXT3=/host/build/data/fs/basic.ext3
EXT4=/host/build/data/fs/basic.ext4
XFS=/host/build/data/fs/basic.xfs
BTRFS=/host/build/data/fs/basic.btrfs

# Get sizes in sectors (512 bytes each), rounded up
sectors() { echo $(( ($(stat -c %s "$1") + 511) / 512 )); }

FAT32_SECTORS=$(sectors "$FAT32")
EXT2_SECTORS=$(sectors "$EXT2")
EXT3_SECTORS=$(sectors "$EXT3")
EXT4_SECTORS=$(sectors "$EXT4")
XFS_SECTORS=$(sectors "$XFS")
BTRFS_SECTORS=$(sectors "$BTRFS")

# GPT layout - partitions start at 2048 (1MB alignment)
# GPT header and entries take first 34 sectors, but we align to 2048

P0_START=2048
P0_SIZE=$FAT32_SECTORS

P1_START=$(( P0_START + P0_SIZE ))
P1_SIZE=$EXT2_SECTORS

P2_START=$(( P1_START + P1_SIZE ))
P2_SIZE=$EXT3_SECTORS

P3_START=$(( P2_START + P2_SIZE ))
P3_SIZE=$EXT4_SECTORS

P4_START=$(( P3_START + P3_SIZE ))
P4_SIZE=$XFS_SECTORS

P5_START=$(( P4_START + P4_SIZE ))
P5_SIZE=$BTRFS_SECTORS

# Total disk size (add space for backup GPT at end)
TOTAL_SECTORS=$(( P5_START + P5_SIZE + 2048 ))
TOTAL_BYTES=$(( TOTAL_SECTORS * 512 ))

truncate -s "$TOTAL_BYTES" "$OUTPUT"

# Create GPT with sfdisk
sfdisk "$OUTPUT" << EOF
label: gpt
start=$P0_START, size=$P0_SIZE, type=EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
start=$P1_START, size=$P1_SIZE, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
start=$P2_START, size=$P2_SIZE, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
start=$P3_START, size=$P3_SIZE, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
start=$P4_START, size=$P4_SIZE, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
start=$P5_START, size=$P5_SIZE, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
EOF

# Copy filesystem images into partitions
dd if="$FAT32" of="$OUTPUT" bs=512 seek=$P0_START conv=notrunc status=none
dd if="$EXT2" of="$OUTPUT" bs=512 seek=$P1_START conv=notrunc status=none
dd if="$EXT3" of="$OUTPUT" bs=512 seek=$P2_START conv=notrunc status=none
dd if="$EXT4" of="$OUTPUT" bs=512 seek=$P3_START conv=notrunc status=none
dd if="$XFS" of="$OUTPUT" bs=512 seek=$P4_START conv=notrunc status=none
dd if="$BTRFS" of="$OUTPUT" bs=512 seek=$P5_START conv=notrunc status=none
