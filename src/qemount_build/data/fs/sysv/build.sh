#!/bin/sh
set -e

OUTPUT_PATH="$1"
BUILD=/host/build

# Copy ext2 source and remove lost+found
# TODO: use tarfs once supported, to avoid this ext2 workaround
cp "$BUILD/tests/data/fs/basic.ext2" /tmp/source.ext2
debugfs -w -R "rmdir lost+found" /tmp/source.ext2 2>/dev/null || true

# Remove symlinks from source - Linux 2.6.39 sysv driver crashes on symlink creation
# (NULL pointer deref in sysv_symlink -> page_symlink). Once we have a guest with
# working sysv symlink support, we can use a custom duplicate script instead.
remove_symlinks() {
    local img="$1" dir="$2"
    debugfs -R "ls -l $dir" "$img" 2>/dev/null | while read -r inode mode rest; do
        name=$(echo "$rest" | awk '{print $NF}')
        [ "$name" = "." ] || [ "$name" = ".." ] && continue
        path="$dir/$name"
        # Symlink: mode starts with 12
        if echo "$mode" | grep -q "^12"; then
            echo "Removing symlink: $path"
            debugfs -w -R "rm $path" "$img" 2>/dev/null || true
        # Directory: mode starts with 4 - recurse
        elif echo "$mode" | grep -q "^4"; then
            remove_symlinks "$img" "$path"
        fi
    done
}
remove_symlinks /tmp/source.ext2 ""

SRC_IMG="/tmp/source.ext2"

# SysV only works on Linux 2.6 (removed from 6.x kernels)
KERNEL="$BUILD/guests/linux/2.6/x86_64/kernel"
BOOT_IMG="$BUILD/guests/linux/rootfs/x86_64/boot.img"
RUN_SCRIPT="$BUILD/common/run/qemu-linux/run-linux.sh"

# Create empty SVR4 filesystem
mkfs.sysv /tmp/output.sysv 4

"$RUN_SCRIPT" x86_64 "$KERNEL" "$BOOT_IMG" \
    -i "$SRC_IMG" -i /tmp/output.sysv -m duplicate

mkdir -p "$(dirname "$BUILD/$OUTPUT_PATH")"
cp /tmp/output.sysv "$BUILD/$OUTPUT_PATH"
