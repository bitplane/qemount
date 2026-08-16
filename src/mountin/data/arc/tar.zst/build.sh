#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .tar.zst)
TAR_PATH="/host/build/tests/data/templates/${BASE_NAME}.tar"

mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

tar -cf - -C /tmp/template . | zstd -o /tmp/output.tar.zst

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.tar.zst "/host/build/$OUTPUT_PATH"
