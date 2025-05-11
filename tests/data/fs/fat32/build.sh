#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .fat32)
TAR_PATH="/host/build/tests/data/templates/${BASE_NAME}.tar"

mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

truncate -s 35M /tmp/output.fat32
mkfs.fat -F 32 -S 512 /tmp/output.fat32

# Use explicit path for mtoolsrc
export MTOOLSRC="/tmp/mtoolsrc"
echo "drive c: file=\"/tmp/output.fat32\"" > "$MTOOLSRC"

# Create directories - Alpine-compatible version
cd /tmp/template
find . -type d | while read -r dir; do
    # Skip current directory
    [ "$dir" = "." ] && continue
    # Remove leading ./
    dir="${dir#./}"
    mmd "c:/$dir" 2>/dev/null || true
done

# Copy files - Alpine-compatible version
find . -type f | while read -r file; do
    # Remove leading ./
    file="${file#./}"
    mcopy -o "/tmp/template/$file" "c:/$file"
done
cd - > /dev/null

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.fat32 "/host/build/$OUTPUT_PATH"