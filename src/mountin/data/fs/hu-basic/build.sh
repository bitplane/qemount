#!/bin/sh
set -e

OUTPUT="/host/build/$1"
TEMPLATE="/host/build/data/templates/basic.tar"

mkdir -p /tmp/hubasic-src
tar -xf "$TEMPLATE" -C /tmp/hubasic-src

# Pack every regular file from the template into a Hu-BASIC 2D image.
mkdir -p "$(dirname "$OUTPUT")"
find /tmp/hubasic-src -type f | sort | xargs python3 /build/mkhubasic.py "$OUTPUT"
