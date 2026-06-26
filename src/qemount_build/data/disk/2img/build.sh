#!/bin/sh
set -e

OUTPUT="/host/build/$1"
INPUT="/host/build/data/fs/basic.prodos"

mkdir -p "$(dirname "$OUTPUT")"
python3 /build/mk2img.py "$OUTPUT" "$INPUT"
