#!/bin/sh
set -e

OUTPUT="/host/build/$1"
TEMPLATE="/host/build/data/templates/basic.tar"

mkdir -p /tmp/rsdos-src
tar -xf "$TEMPLATE" -C /tmp/rsdos-src

# Pack the template tree (the tar holds a top-level `basic/` directory) into a
# fresh RS-DOS disk. RS-DOS is flat, so nested files are flattened to 8.3.
mkdir -p "$(dirname "$OUTPUT")"
python3 /build/mkrsdos.py "$OUTPUT" /tmp/rsdos-src/basic
