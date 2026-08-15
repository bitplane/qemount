#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
python3 /build/mklbr.py "/host/build/$OUTPUT_PATH" "$INPUT"
