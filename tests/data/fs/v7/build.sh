#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .v7)
TAR_PATH="/host/build/tests/data/templates/${BASE_NAME}.tar"

mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

# V7 filesystem - use NetBSD's makefs with v7fs support
# Size in bytes (4MB should be plenty for test data)
makefs -t v7fs -s 4194304 /tmp/output.v7 /tmp/template

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.v7 "/host/build/$OUTPUT_PATH"
