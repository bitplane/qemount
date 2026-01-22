#!/bin/sh
set -e

OUTPUT="/host/build/$1"
mkdir -p "$(dirname "$OUTPUT")"

UFS1=/host/build/data/fs/basic.ufs1
UFS2=/host/build/data/fs/basic.ufs2

# Create ~22MB raw disk (45056 sectors)
dd if=/dev/zero of="$OUTPUT" bs=512 count=45056

# Apply disklabel (-M amd64 for machine type)
nbdisklabel -M amd64 -R -F "$OUTPUT" /disklabel.proto

# Write filesystem images to partitions
# Partition a starts at sector 2048
dd if="$UFS1" of="$OUTPUT" bs=512 seek=2048 conv=notrunc

# Partition e starts at sector 22528
dd if="$UFS2" of="$OUTPUT" bs=512 seek=22528 conv=notrunc
