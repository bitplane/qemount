#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .ntfs)

# For now, just create an empty NTFS filesystem
truncate -s 20M /tmp/output.ntfs
mkntfs -F -f -Q /tmp/output.ntfs

echo "Warning: Created empty NTFS filesystem (Alpine doesn't have ntfsmkdir/ntfscp)"

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.ntfs "/host/build/$OUTPUT_PATH"