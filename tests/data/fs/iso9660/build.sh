#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .iso9660)
TAR_PATH="/host/build/tests/data/templates/${BASE_NAME}.tar"

mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

genisoimage -r -J -o /tmp/output.iso /tmp/template

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.iso "/host/build/$OUTPUT_PATH"
