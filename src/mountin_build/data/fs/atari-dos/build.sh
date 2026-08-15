#!/bin/sh
set -e

OUTPUT="/host/build/$1"
TEMPLATE="/host/build/data/templates/basic.tar"

mkdir -p /tmp/atari-src
tar -xf "$TEMPLATE" -C /tmp/atari-src

# Pack the template tree (the tar holds a top-level `basic/` directory) into a
# fresh Atari DOS 2.0S single-density disk. The output has no .atr extension, so
# mkataridos writes a bare raw sector image (the inner filesystem).
mkdir -p "$(dirname "$OUTPUT")"
python3 /build/mkataridos.py create --density sd "$OUTPUT" /tmp/atari-src/basic
