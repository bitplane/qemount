#!/bin/bash
# Creates a FAT32 filesystem image in userspace without root privileges
set -eo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source_dir> <output.fat32>"
    exit 1
fi

SRC_DIR="$1"
OUTPUT="$2"

# FAT32 valid sizes - at least 33MB, max 2TB
MIN_SIZE=33792  # 33MB in KB
MAX_SIZE=2199023255  # 2TB in KB (theoretical maximum)

# Calculate size needed (source size + 20% overhead)
SIZE=$(du -s -k "$SRC_DIR" | awk '{print int($1 * 1.2)}')
if [ $SIZE -lt $MIN_SIZE ]; then
    SIZE=$MIN_SIZE  # Minimum for FAT32
elif [ $SIZE -gt $MAX_SIZE ]; then
    echo "Warning: Source too large for FAT32, maximum size is 2TB"
    SIZE=$MAX_SIZE
fi

# Create the image file
echo "Creating $SIZE KB FAT32 image..."
truncate -s ${SIZE}K "$OUTPUT"

# Format as FAT32 (using mkfs.fat with -F 32)
# Add -S 512 to specify sector size explicitly
mkfs.fat -F 32 -S 512 "$OUTPUT"

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

echo "Created FAT32 image: $OUTPUT"