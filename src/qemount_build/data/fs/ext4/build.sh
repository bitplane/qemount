#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .ext4)
TAR_PATH="/host/build/tests/data/templates/${BASE_NAME}.tar"

mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

truncate -s 10M /tmp/output.ext4
mke2fs -t ext4 -d /tmp/template /tmp/output.ext4

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.ext4 "/host/build/$OUTPUT_PATH"
