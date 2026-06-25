#!/bin/sh
set -e

OUTPUT="/host/build/$1"
TEMPLATE="/host/build/data/templates/basic.tar"

mkdir -p /tmp/scl-src
tar -xf "$TEMPLATE" -C /tmp/scl-src

# Pack every regular file from the template into the SCL.
mkdir -p "$(dirname "$OUTPUT")"
find /tmp/scl-src -type f | sort | xargs python3 /build/mkscl.py "$OUTPUT"
