#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .erofs)
TAR_PATH="/host/build/tests/data/templates/${BASE_NAME}.tar"

mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

mkfs.erofs /tmp/output.erofs /tmp/template

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.erofs "/host/build/$OUTPUT_PATH"
