#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .tar.lzma)
TAR_PATH="/host/build/data/templates/${BASE_NAME}.tar"

lzma < "$TAR_PATH" > /tmp/output.tar.lzma

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.tar.lzma "/host/build/$OUTPUT_PATH"
