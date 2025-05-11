#!/bin/sh
set -e

OUTPUT_PATH="$1"

# Create empty exFAT filesystem for Alpine
# (mounting requires privileges we don't have in container)
truncate -s 128M /tmp/output.exfat
mkfs.exfat /tmp/output.exfat

echo "Warning: Created empty exFAT filesystem (populating requires mount privileges)"

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.exfat "/host/build/$OUTPUT_PATH"