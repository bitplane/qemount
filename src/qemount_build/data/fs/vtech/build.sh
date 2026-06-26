#!/bin/sh
set -e

OUTPUT="/host/build/$1"
TEMPLATE="/host/build/data/templates/basic.tar"

mkdir -p /tmp/vtech-src
tar -xf "$TEMPLATE" -C /tmp/vtech-src

# Pack the template tree (the tar holds a top-level `basic/` directory) into a
# fresh VZ-DOS disk. VZ-DOS is flat, so nested files are flattened to 8 chars.
mkdir -p "$(dirname "$OUTPUT")"
python3 /build/mkvtech.py "$OUTPUT" /tmp/vtech-src/basic
