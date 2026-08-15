#!/bin/sh
set -e

OUTPUT="/host/build/$1"
TEMPLATE="/host/build/data/templates/basic.tar"

rm -rf /tmp/cbm-src /tmp/cbm-flat
mkdir -p /tmp/cbm-src /tmp/cbm-flat
tar -xf "$TEMPLATE" -C /tmp/cbm-src

# CBM DOS is flat; flatten the tree. `find -type f` skips symlinks and dirs.
find /tmp/cbm-src/basic -type f -exec cp {} /tmp/cbm-flat/ \;

mkdir -p "$(dirname "$OUTPUT")"
rm -f "$OUTPUT"

# Write a 1541 .d64 from the (native-format) input files.
cd /tmp/cbm-flat
cbmconvert -n -D4 "$OUTPUT" *
