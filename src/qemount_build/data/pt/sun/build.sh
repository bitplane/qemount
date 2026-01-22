#!/bin/sh
# $1 = output file (e.g. data/pt/basic.sun)
set -e

OUTPUT="/host/build/$1"
mkdir -p "$(dirname "$OUTPUT")"

UFS1=/host/build/data/fs/basic.ufs1
UFS2=/host/build/data/fs/basic.ufs2

UFS1_SIZE=$(stat -c %s "$UFS1")
UFS2_SIZE=$(stat -c %s "$UFS2")

# Round up to 1MB alignment (2048 sectors)
UFS1_SECTORS=$(( (UFS1_SIZE + 1048575) / 512 / 2048 * 2048 ))
UFS2_SECTORS=$(( (UFS2_SIZE + 1048575) / 512 / 2048 * 2048 ))

# Sun labels need cylinder alignment. Parted uses geometry: 4 heads × 32 sectors = 128 sectors/cyl
# Cylinder 0 is reserved for the Sun label - partitions start at cylinder 1
SPC=128  # sectors per cylinder (parted default for small images)
P0_CYL=$(( UFS1_SECTORS / SPC ))
P1_CYL=$(( UFS2_SECTORS / SPC ))
# +2: one for label (cyl 0), one for padding at end
TOTAL_CYL=$(( 1 + P0_CYL + P1_CYL + 1 ))

# Partition layout:
# Cylinder 0: Sun label (reserved)
# Cylinder 1 to 1+P0_CYL-1: partition 0 (UFS1)
# Cylinder 1+P0_CYL to end: partition 1 (UFS2)
P0_START=$(( 1 * SPC ))
P0_END=$(( (1 + P0_CYL) * SPC - 1 ))
P1_START=$(( (1 + P0_CYL) * SPC ))
P1_END=$(( (1 + P0_CYL + P1_CYL) * SPC - 1 ))

# Create disk image
truncate -s $(( TOTAL_CYL * SPC * 512 )) "$OUTPUT"

# Create Sun label with parted
parted -s "$OUTPUT" mklabel sun
parted -s "$OUTPUT" mkpart ${P0_START}s ${P0_END}s
parted -s "$OUTPUT" mkpart ${P1_START}s ${P1_END}s

# Copy filesystem images to partition start offsets
dd if="$UFS1" of="$OUTPUT" bs=512 seek=$P0_START conv=notrunc status=none
dd if="$UFS2" of="$OUTPUT" bs=512 seek=$P1_START conv=notrunc status=none
