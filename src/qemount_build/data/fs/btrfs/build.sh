#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .btrfs)
TAR_PATH="/host/build/tests/data/templates/${BASE_NAME}.tar"

mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

# Btrfs needs at least 16MB (often more)
truncate -s 64M /tmp/output.btrfs
mkfs.btrfs -q --rootdir /tmp/template /tmp/output.btrfs

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.btrfs "/host/build/$OUTPUT_PATH"
