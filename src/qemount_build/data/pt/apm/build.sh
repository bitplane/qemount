#!/bin/sh
# $1 = output file (e.g. data/pt/basic.apm)
set -e

OUTPUT="/host/build/$1"
mkdir -p "$(dirname "$OUTPUT")"

HFS=/host/build/data/fs/basic.hfs
HFSPLUS=/host/build/data/fs/basic.hfsplus
PRODOS=/host/build/data/fs/basic.prodos

HFS_SIZE=$(stat -c %s "$HFS")
HFSPLUS_SIZE=$(stat -c %s "$HFSPLUS")
PRODOS_SIZE=$(stat -c %s "$PRODOS")

# Partition sizes in 512-byte sectors (round up to 1MB alignment)
HFS_SECTORS=$(( (HFS_SIZE + 1048575) / 512 / 2048 * 2048 ))
HFSPLUS_SECTORS=$(( (HFSPLUS_SIZE + 1048575) / 512 / 2048 * 2048 ))
PRODOS_SECTORS=$(( (PRODOS_SIZE + 1048575) / 512 / 2048 * 2048 ))

# Layout: block 0 = DDM, blocks 1-63 = partition map, then partitions
MAP_BLOCKS=64
P1_START=$MAP_BLOCKS
P1_END=$(( P1_START + HFS_SECTORS - 1 ))
P2_START=$(( P1_END + 1 ))
P2_END=$(( P2_START + HFSPLUS_SECTORS - 1 ))
P3_START=$(( P2_END + 1 ))
P3_END=$(( P3_START + PRODOS_SECTORS - 1 ))

TOTAL_SECTORS=$(( P3_END + 2048 ))

# Create disk image
truncate -s $(( TOTAL_SECTORS * 512 )) "$OUTPUT"

# Create APM with parted. parted has no ProDOS fs hint, so the third partition
# is created untyped; we patch its type string to Apple_PRODOS below.
parted -s "$OUTPUT" mklabel mac
parted -s "$OUTPUT" mkpart primary hfs ${P1_START}s ${P1_END}s
parted -s "$OUTPUT" mkpart primary hfs+ ${P2_START}s ${P2_END}s
parted -s "$OUTPUT" mkpart primary ${P3_START}s ${P3_END}s

# Patch the third data partition's type field to "Apple_PRODOS".
# Map entries: block 1 = self (Apple_partition_map), blocks 2..4 = data
# partitions in creation order; the type field is at entry offset 48 (32 bytes).
PRODOS_TYPE_OFF=$(( 4 * 512 + 48 ))
dd if=/dev/zero of="$OUTPUT" bs=1 seek=$PRODOS_TYPE_OFF count=32 conv=notrunc status=none
printf 'Apple_PRODOS' | dd of="$OUTPUT" bs=1 seek=$PRODOS_TYPE_OFF conv=notrunc status=none

# Copy filesystem images
dd if="$HFS" of="$OUTPUT" bs=512 seek=$P1_START conv=notrunc status=none
dd if="$HFSPLUS" of="$OUTPUT" bs=512 seek=$P2_START conv=notrunc status=none
dd if="$PRODOS" of="$OUTPUT" bs=512 seek=$P3_START conv=notrunc status=none
