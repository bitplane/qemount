#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .romfs)
TAR_PATH="/host/build/tests/data/templates/${BASE_NAME}.tar"

mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

# genromfs creates directly from directory
genromfs -f /tmp/output.romfs -d /tmp/template -V "basic"

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.romfs "/host/build/$OUTPUT_PATH"
