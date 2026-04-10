#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .tar.lz4)
TAR_PATH="/host/build/data/templates/${BASE_NAME}.tar"

lz4 < "$TAR_PATH" > /tmp/output.tar.lz4

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.tar.lz4 "/host/build/$OUTPUT_PATH"
