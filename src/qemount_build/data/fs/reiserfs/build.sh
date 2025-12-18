#!/bin/sh
set -e

OUTPUT_PATH="$1"
BUILD=/host/build

# Copy ext2 source and remove lost+found
# TODO: use tarfs once supported, to avoid this ext2 workaround
cp "$BUILD/tests/data/fs/basic.ext2" /tmp/source.ext2
debugfs -w -R "rmdir lost+found" /tmp/source.ext2 2>/dev/null || true
SRC_IMG="/tmp/source.ext2"

# ReiserFS only works on Linux 2.6 (removed from 6.x kernels)
KERNEL="$BUILD/guests/linux/2.6/x86_64/kernel"
BOOT_IMG="$BUILD/guests/linux/rootfs/x86_64/boot.img"
RUN_SCRIPT="$BUILD/common/run/qemu-linux/run-linux.sh"

# ReiserFS needs at least 32MB
truncate -s 64M /tmp/output.reiserfs
mkfs.reiserfs -ff -q /tmp/output.reiserfs

"$RUN_SCRIPT" x86_64 "$KERNEL" "$BOOT_IMG" \
    -i "$SRC_IMG" -i /tmp/output.reiserfs -m duplicate

mkdir -p "$(dirname "$BUILD/$OUTPUT_PATH")"
cp /tmp/output.reiserfs "$BUILD/$OUTPUT_PATH"
