#!/bin/sh
set -e

OUTPUT="/host/build/$1"
TEMPLATE="/host/build/data/templates/basic.tar"

mkdir -p /tmp/prodos-src
tar -xf "$TEMPLATE" -C /tmp/prodos-src

# Pack the template tree (the tar holds a top-level `basic/` directory) into a
# fresh ProDOS volume, preserving subdirectories.
mkdir -p "$(dirname "$OUTPUT")"
python3 /build/mkprodos.py "$OUTPUT" /tmp/prodos-src/basic
