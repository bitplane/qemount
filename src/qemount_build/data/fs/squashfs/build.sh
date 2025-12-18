#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .squashfs)
TAR_PATH="/host/build/tests/data/templates/${BASE_NAME}.tar"

mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

mksquashfs /tmp/template /tmp/output.squashfs -comp gzip

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.squashfs "/host/build/$OUTPUT_PATH"
