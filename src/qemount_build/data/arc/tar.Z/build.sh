#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .tar.Z)
TAR_PATH="/host/build/data/templates/${BASE_NAME}.tar"

compress < "$TAR_PATH" > /tmp/output.tar.Z

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.tar.Z "/host/build/$OUTPUT_PATH"
