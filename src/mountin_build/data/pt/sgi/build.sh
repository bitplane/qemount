#!/bin/sh
# $1 = output file (e.g. data/pt/basic.sgi)
set -e

OUTPUT="/host/build/$1"
mkdir -p "$(dirname "$OUTPUT")"

XFS=/host/build/data/fs/basic.xfs
XFS_SIZE=$(stat -c %s "$XFS")

# Round up to 1MB alignment (2048 sectors)
XFS_SECTORS=$(( (XFS_SIZE + 1048575) / 512 / 2048 * 2048 ))

# SGI DVH: volume header requires first 4096 sectors (2MB)
P_START=4096
TOTAL_SECTORS=$(( P_START + XFS_SECTORS + 2048 ))

truncate -s $(( TOTAL_SECTORS * 512 )) "$OUTPUT"

# Create SGI DVH with parted
parted -s "$OUTPUT" mklabel dvh
parted -s "$OUTPUT" mkpart primary xfs ${P_START}s $(( P_START + XFS_SECTORS - 1 ))s

# Copy filesystem image
dd if="$XFS" of="$OUTPUT" bs=512 seek=$P_START conv=notrunc status=none
