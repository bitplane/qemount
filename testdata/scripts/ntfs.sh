#!/bin/bash
# Creates an NTFS filesystem image with files in userspace without requiring mount
set -eo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source_dir> <output.ntfs>"
    exit 1
fi

SRC_DIR="$1"
OUTPUT="$2"

# Check for required tools
if ! command -v mkntfs >/dev/null 2>&1; then
    echo "Error: mkntfs not found. Please install ntfs-3g package."
    exit 1
fi

if ! command -v ntfscp >/dev/null 2>&1; then
    echo "Error: ntfscp not found. Please install ntfs-3g package."
    exit 1
fi

# NTFS needs a reasonable minimum size
MIN_SIZE=20480  # 20MB in KB

# Calculate size needed (source size + 20% overhead)
SIZE=$(du -s -k "$SRC_DIR" | awk '{print int($1 * 1.2)}')
if [ $SIZE -lt $MIN_SIZE ]; then
    SIZE=$MIN_SIZE
fi

# Create the image file
echo "Creating $SIZE KB NTFS image..."
truncate -s ${SIZE}K "$OUTPUT"

# Format as NTFS (with quick format)
echo "Formatting as NTFS..."
mkntfs -F -f -Q "$OUTPUT"

# Create directories first (recursive scan)
echo "Creating directories..."
find "$SRC_DIR" -type d | while read -r dir; do
    # Skip the source directory itself
    if [ "$dir" = "$SRC_DIR" ]; then
        continue
    fi
    
    # Get relative path
    REL_PATH="${dir#$SRC_DIR/}"
    
    # Create this directory on the NTFS image
    echo "  Creating directory: $REL_PATH"
    ntfsmkdir "$OUTPUT" "/$REL_PATH"
done

# Copy files using ntfscp
echo "Copying files..."
find "$SRC_DIR" -type f | while read -r file; do
    # Get relative path
    REL_PATH="${file#$SRC_DIR/}"
    
    # Copy the file to NTFS image
    echo "  Copying file: $REL_PATH"
    ntfscp "$OUTPUT" "$file" "/$REL_PATH"
done

echo "Created NTFS image: $OUTPUT"