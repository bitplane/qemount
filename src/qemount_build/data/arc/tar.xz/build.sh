#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .tar.xz)
TAR_PATH="/host/build/tests/data/templates/${BASE_NAME}.tar"

mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

tar -cJf /tmp/output.tar.xz -C /tmp/template .

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.tar.xz "/host/build/$OUTPUT_PATH"
