#!/bin/sh
# $1 = output file (e.g. data/pt/basic.rdb)
set -e

OUTPUT="/host/build/$1"
mkdir -p "$(dirname "$OUTPUT")"

FFS=/host/build/data/fs/basic.amiga-ffs
OFS=/host/build/data/fs/basic.amiga-ofs

# rdbtool default geometry: heads=1, sectors=32, block_size=512
# cyl_blks = 32, so cylinders = (size / 512) / 32
CYL_BLKS=32
BLOCK_SIZE=512

cyls_for_file() {
    size=$(stat -c %s "$1")
    blocks=$(( size / BLOCK_SIZE ))
    echo $(( blocks / CYL_BLKS ))
}

FFS_CYLS=$(cyls_for_file "$FFS")
OFS_CYLS=$(cyls_for_file "$OFS")

# Partition layout (cylinder 0-1 reserved for RDB)
P1_START=2
P1_END=$(( P1_START + FFS_CYLS - 1 ))
P2_START=$(( P1_END + 1 ))
P2_END=$(( P2_START + OFS_CYLS - 1 ))

# Total size with padding
TOTAL_CYLS=$(( P2_END + 10 ))
TOTAL_BYTES=$(( TOTAL_CYLS * CYL_BLKS * BLOCK_SIZE ))

rm -f "$OUTPUT"
rdbtool -f "$OUTPUT" create size=$TOTAL_BYTES \
    + init \
    + add start=$P1_START end=$P1_END dostype=DOS3 \
    + add start=$P2_START end=$P2_END dostype=DOS0 \
    + import 0 "$FFS" \
    + import 1 "$OFS"
