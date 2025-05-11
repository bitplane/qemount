#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .fat16)
TAR_PATH="/host/build/tests/data/templates/${BASE_NAME}.tar"

mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

truncate -s 16M /tmp/output.fat16
mkfs.fat -F 16 -S 512 /tmp/output.fat16

echo "drive c: file=\"/tmp/output.fat16\"" > ~/.mtoolsrc

# Create directories
find /tmp/template -type d -printf "%P\n" | sort | while read -r dir; do
    [ -z "$dir" ] && continue
    mmd "c:/$dir"
done

# Copy files
find /tmp/template -type f -printf "%P\n" | while read -r file; do
    [ -z "$file" ] && continue
    mcopy -o "/tmp/template/$file" "c:/$file"
done

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.fat16 "/host/build/$OUTPUT_PATH"
