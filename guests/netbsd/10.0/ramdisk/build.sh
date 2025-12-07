#!/bin/sh
# Build the ramdisk directory structure with rescue binaries
set -eu

DESTDIR="$1"
RAMDISK="$2"

mkdir -p "$RAMDISK/bin" "$RAMDISK/sbin" "$RAMDISK/dev" "$RAMDISK/etc" \
         "$RAMDISK/mnt" "$RAMDISK/tmp" "$RAMDISK/proc" "$RAMDISK/kern"

# Copy rescue binary (statically linked crunchgen)
cp "$DESTDIR/rescue/sh" "$RAMDISK/bin/sh"

# Hard link all the commands we need to the same binary
for cmd in ls cat echo mkdir sleep test "["; do
    ln "$RAMDISK/bin/sh" "$RAMDISK/bin/$cmd"
done

for cmd in mount mount_ffs mount_cd9660 mount_msdos mount_ext2fs \
           mount_kernfs mount_procfs mount_ptyfs \
           umount halt reboot init; do
    ln "$RAMDISK/bin/sh" "$RAMDISK/sbin/$cmd"
done

# Rename real init so our script can call it if needed
mv "$RAMDISK/sbin/init" "$RAMDISK/sbin/init.real"

echo "Ramdisk built: $(du -sh "$RAMDISK" | cut -f1)"
