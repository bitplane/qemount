#!/bin/bash
# Creates an exFAT filesystem image in userspace without root privileges
set -eo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source_dir> <output.exfat>"
    exit 1
fi

SRC_DIR="$1"
OUTPUT="$2"

# Check for required tools - both are required
if ! command -v mkfs.exfat >/dev/null 2>&1; then
    echo "Error: mkfs.exfat not found. Please install exfatprogs package."
    exit 1
fi

if ! command -v mount.exfat >/dev/null 2>&1; then
    echo "Error: mount.exfat not found. Please install fuse-exfat package."
    exit 1
fi

# exFAT valid sizes - minimum about 128MB is recommended
MIN_SIZE=131072  # 128MB in KB

# Calculate size needed (source size + 20% overhead)
SIZE=$(du -s -k "$SRC_DIR" | awk '{print int($1 * 1.2)}')
if [ $SIZE -lt $MIN_SIZE ]; then
    SIZE=$MIN_SIZE  # Minimum for reliable exFAT
fi

# Create the image file
echo "Creating $SIZE KB exFAT image..."
truncate -s ${SIZE}K "$OUTPUT"

# Format as exFAT
mkfs.exfat "$OUTPUT"

# Mount the image to copy files
TEMP_MOUNT=$(mktemp -d)
if ! mount.exfat "$OUTPUT" "$TEMP_MOUNT"; then
    echo "Error: Failed to mount exFAT image."
    rm -f "$OUTPUT"
    rmdir "$TEMP_MOUNT"
    exit 1
fi

# Copy files to the mounted image
echo "Copying files to exFAT image..."
cp -a "$SRC_DIR"/* "$TEMP_MOUNT"/ 2>/dev/null || true

# Unmount
fusermount -u "$TEMP_MOUNT"
rmdir "$TEMP_MOUNT"

echo "Created exFAT image: $OUTPUT"