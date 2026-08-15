#!/bin/sh
set -e

OUTPUT="/host/build/$1"
INPUT="/host/build/data/fs/basic.atari-dos"

mkdir -p "$(dirname "$OUTPUT")"
python3 /build/mkatr.py "$OUTPUT" "$INPUT"
