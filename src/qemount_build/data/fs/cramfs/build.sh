#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .cramfs)
TAR_PATH="/host/build/tests/data/templates/${BASE_NAME}.tar"

mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

# Use mkcramfs instead of mkfs.cramfs
mkcramfs /tmp/template /tmp/output.cramfs

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.cramfs "/host/build/$OUTPUT_PATH"