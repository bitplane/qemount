#!/bin/sh
# $1 = output file (relative path, e.g. data/pt/hybrid.gpt)
set -e

OUTPUT="/host/build/$1"
mkdir -p "$(dirname "$OUTPUT")"

# Filesystem images
FAT32=/host/build/data/fs/basic.fat32
EXT4=/host/build/data/fs/basic.ext4
XFS=/host/build/data/fs/basic.xfs

# Get sizes in sectors (512 bytes each), rounded up
sectors() { echo $(( ($(stat -c %s "$1") + 511) / 512 )); }

FAT32_SECTORS=$(sectors "$FAT32")
EXT4_SECTORS=$(sectors "$EXT4")
XFS_SECTORS=$(sectors "$XFS")

# GPT layout - partitions start at 2048 (1MB alignment)
P0_START=2048
P0_SIZE=$FAT32_SECTORS

P1_START=$(( P0_START + P0_SIZE ))
P1_SIZE=$EXT4_SECTORS

P2_START=$(( P1_START + P1_SIZE ))
P2_SIZE=$XFS_SECTORS

# Total disk size (add space for backup GPT at end)
TOTAL_SECTORS=$(( P2_START + P2_SIZE + 2048 ))
TOTAL_BYTES=$(( TOTAL_SECTORS * 512 ))

truncate -s "$TOTAL_BYTES" "$OUTPUT"

# Create GPT with sfdisk first
sfdisk "$OUTPUT" << EOF
label: gpt
start=$P0_START, size=$P0_SIZE, type=EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
start=$P1_START, size=$P1_SIZE, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
start=$P2_START, size=$P2_SIZE, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
EOF

# Convert to hybrid MBR using gdisk (sgdisk not available in Alpine)
# Mirrors all 3 GPT partitions into MBR. In real hybrid scenarios (e.g., Intel Macs),
# MBR often has fewer partitions since it's limited to 4 slots (3 usable with 0xEE).
# r=recovery menu, h=hybrid MBR, partitions 1-3, N=no EFI first,
# accept defaults for type codes, N=not bootable for each, N=don't protect more, w=write, Y=confirm
printf 'r\nh\n1 2 3\nN\n\nN\n\nN\n\nN\nN\nw\nY\n' | gdisk "$OUTPUT"

# Copy filesystem images into partitions
dd if="$FAT32" of="$OUTPUT" bs=512 seek=$P0_START conv=notrunc status=none
dd if="$EXT4" of="$OUTPUT" bs=512 seek=$P1_START conv=notrunc status=none
dd if="$XFS" of="$OUTPUT" bs=512 seek=$P2_START conv=notrunc status=none
