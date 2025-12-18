#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .cpio)
TAR_PATH="/host/build/tests/data/templates/${BASE_NAME}.tar"

mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

cd /tmp/template
find . | cpio -o -H newc > /tmp/output.cpio

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.cpio "/host/build/$OUTPUT_PATH"
