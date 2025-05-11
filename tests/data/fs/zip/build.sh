#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .zip)
TAR_PATH="/host/build/tests/data/templates/${BASE_NAME}.tar"

mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

cd /tmp/template
zip -r /tmp/output.zip .

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.zip "/host/build/$OUTPUT_PATH"
