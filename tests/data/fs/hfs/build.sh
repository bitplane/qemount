#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .hfs)
TAR_PATH="/host/build/tests/data/templates/${BASE_NAME}.tar"

mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

truncate -s 8M /tmp/output.hfs
hformat -l "basic" /tmp/output.hfs

# Mount the HFS image (userspace, sets current volume)
hmount /tmp/output.hfs

# Create directories (HFS uses : as path separator)
cd /tmp/template
find . -type d | sort | while read -r dir; do
    [ "$dir" = "." ] && continue
    dir="${dir#./}"
    hfs_dir=$(echo "$dir" | tr '/' ':')
    hmkdir ":$hfs_dir" 2>/dev/null || true
done

# Copy files (HFS doesn't support symlinks, skip them)
find . -type f | while read -r file; do
    file="${file#./}"
    dir=$(dirname "$file")
    base=$(basename "$file")
    if [ "$dir" = "." ]; then
        hcopy "/tmp/template/$file" ":$base"
    else
        hfs_dir=$(echo "$dir" | tr '/' ':')
        hcopy "/tmp/template/$file" ":$hfs_dir:$base"
    fi
done
cd - > /dev/null

humount

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.hfs "/host/build/$OUTPUT_PATH"
