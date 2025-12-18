#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .ext2)
TAR_PATH="/host/build/tests/data/templates/${BASE_NAME}.tar"

mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

truncate -s 10M /tmp/output.ext2
mke2fs -t ext2 -d /tmp/template /tmp/output.ext2

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.ext2 "/host/build/$OUTPUT_PATH"
