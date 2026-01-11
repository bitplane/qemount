#!/bin/sh
set -e

# Read output path from META
OUTPUT=$(echo "$META" | jq -r '.provides | keys[0]')
BASE_NAME=$(basename "$OUTPUT" .ext4)
TAR_PATH="/host/build/data/templates/${BASE_NAME}.tar"

mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

truncate -s 10M /tmp/output.ext4
mke2fs -t ext4 -d /tmp/template /tmp/output.ext4

mkdir -p "$(dirname "/host/build/$OUTPUT")"
cp /tmp/output.ext4 "/host/build/$OUTPUT"
