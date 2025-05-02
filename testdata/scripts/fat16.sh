#!/bin/bash
# Creates a FAT16 filesystem image in userspace without root privileges
set -eo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source_dir> <output.fat16>"
    exit 1
fi

SRC_DIR="$1"
OUTPUT="$2"

# FAT16 valid sizes - at least 16MB recommended, max 2GB
MIN_SIZE=16384  # 16MB in KB
MAX_SIZE=2097152  # 2GB in KB

# Calculate size needed (source size + 20% overhead)
SIZE=$(du -s -k "$SRC_DIR" | awk '{print int($1 * 1.2)}')
if [ $SIZE -lt $MIN_SIZE ]; then
    SIZE=$MIN_SIZE  # Minimum for reliable FAT16
elif [ $SIZE -gt $MAX_SIZE ]; then
    echo "Warning: Source too large for FAT16, maximum size is 2GB"
    SIZE=$MAX_SIZE
fi

# Create the image file
echo "Creating $SIZE KB FAT16 image..."
truncate -s ${SIZE}K "$OUTPUT"

# Format as FAT16 (using mkfs.fat with -F 16)
# Add -S 512 to specify sector size explicitly
mkfs.fat -F 16 -S 512 "$OUTPUT"

# Copy files into the image using mtools
export MTOOLSRC="$(mktemp)"
echo "drive c: file=\"$OUTPUT\"" > "$MTOOLSRC"

# Create directories and copy files
find "$SRC_DIR" -type d -printf "%P\n" | sort | while read -r dir; do
    [ -z "$dir" ] && continue
    mmd "c:/$dir"
done

find "$SRC_DIR" -type f -printf "%P\n" | while read -r file; do
    mcopy -o "$SRC_DIR/$file" "c:/$file"
done

# Clean up temporary file
rm -f "$MTOOLSRC"

echo "Created FAT16 image: $OUTPUT"