#!/bin/sh
set -e
OUTPUT="/host/build/$1"
INPUT="/host/build/data/fs/basic.iso9660"
mkdir -p "$(dirname "$OUTPUT")"
create_compressed_fs "$INPUT" "$OUTPUT"
