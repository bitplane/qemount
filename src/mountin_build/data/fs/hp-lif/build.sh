#!/bin/sh
set -e

OUTPUT="/host/build/$1"
TEMPLATE="/host/build/data/templates/basic.tar"

mkdir -p /tmp/hplif-src
tar -xf "$TEMPLATE" -C /tmp/hplif-src

# Pack the template tree (the tar holds a top-level `basic/` directory) into a
# fresh LIF volume. LIF is flat, so nested files are flattened to 10 chars.
mkdir -p "$(dirname "$OUTPUT")"
python3 /build/mkhplif.py "$OUTPUT" /tmp/hplif-src/basic
