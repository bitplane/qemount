#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .ntfs)

# Create empty NTFS filesystem for Alpine
# (Alpine's ntfs-3g doesn't include ntfsmkdir/ntfscp)
truncate -s 20M /tmp/output.ntfs
mkntfs -F -f -Q /tmp/output.ntfs

echo "Warning: Created empty NTFS filesystem (Alpine lacks directory creation tools)"

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.ntfs "/host/build/$OUTPUT_PATH"