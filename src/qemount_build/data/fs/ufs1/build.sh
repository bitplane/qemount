#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .ufs1)
TAR_PATH="/host/build/tests/data/templates/${BASE_NAME}.tar"

mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

makefs -t ffs -o version=1 -s 10m /tmp/output.ufs1 /tmp/template

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.ufs1 "/host/build/$OUTPUT_PATH"
