#!/bin/sh
set -e

OUTPUT_PATH="$1"
BUILD=/host/build

# Copy ext2 source and remove lost+found
# TODO: use tarfs once supported, to avoid this ext2 workaround
cp "$BUILD/tests/data/fs/basic.ext2" /tmp/source.ext2
debugfs -w -R "rmdir lost+found" /tmp/source.ext2 2>/dev/null || true
SRC_IMG="/tmp/source.ext2"

# QEMU components
KERNEL="$BUILD/guests/linux/6.17/x86_64/kernel"
BOOT_IMG="$BUILD/guests/linux/rootfs/x86_64/boot.img"
RUN_SCRIPT="$BUILD/common/run/qemu-linux/run-linux.sh"

# Create empty NTFS filesystem
truncate -s 32M /tmp/output.ntfs
mkfs.ntfs -F /tmp/output.ntfs

# Run qemu to duplicate ext4 → ntfs
"$RUN_SCRIPT" x86_64 "$KERNEL" "$BOOT_IMG" \
    -i "$SRC_IMG" -i /tmp/output.ntfs -m duplicate

mkdir -p "$(dirname "$BUILD/$OUTPUT_PATH")"
cp /tmp/output.ntfs "$BUILD/$OUTPUT_PATH"
