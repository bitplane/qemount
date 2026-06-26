#!/bin/sh
set -e

OUTPUT="/host/build/$1"
TEMPLATE="/host/build/data/templates/basic.tar"

mkdir -p /tmp/oric-src
tar -xf "$TEMPLATE" -C /tmp/oric-src

# Pack the template tree (the tar holds a top-level `basic/` directory) into a
# fresh Oric Jasmin disk. The filesystem is flat, so nested files are flattened.
mkdir -p "$(dirname "$OUTPUT")"
python3 /build/mkoricjasmin.py "$OUTPUT" /tmp/oric-src/basic
