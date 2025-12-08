#!/bin/sh
# Build the ramdisk directory structure with rescue binaries
set -eu

DESTDIR="$1"
RAMDISK="$2"

mkdir -p "$RAMDISK/bin" "$RAMDISK/sbin" "$RAMDISK/dev" "$RAMDISK/etc" \
         "$RAMDISK/mnt" "$RAMDISK/tmp" "$RAMDISK/proc" "$RAMDISK/kern"

# Copy rescue binary (statically linked crunchgen multicall)
# All commands are hard-linked to this one binary - it uses argv[0] to dispatch
RESCUE="$RAMDISK/.rescue"
cp "$DESTDIR/rescue/sh" "$RESCUE"

# Hard link all the commands we need (only those compiled into rescue!)
# Check rescue help output for available commands
for cmd in sh ls cat echo mkdir sleep test "[" mknod \
           grep egrep fgrep dd cp mv rm ln chmod \
           less more vi ed df ps kill pwd hostname expr stty; do
    ln "$RESCUE" "$RAMDISK/bin/$cmd"
done

for cmd in mount mount_ffs mount_cd9660 mount_msdos mount_ext2fs \
           mount_ados mount_efs mount_filecore mount_lfs mount_ntfs \
           mount_kernfs mount_procfs mount_ptyfs mount_tmpfs mount_mfs \
           mount_null mount_overlay mount_umap mount_union mount_udf \
           umount halt reboot init ifconfig sysctl \
           dmesg fsck fsck_ffs newfs newfs_msdos disklabel fdisk \
           route ping chown chroot; do
    ln "$RESCUE" "$RAMDISK/sbin/$cmd"
done

# Rename real init so our script can call it if needed
mv "$RAMDISK/sbin/init" "$RAMDISK/sbin/init.real"

# Remove the base rescue copy (all links remain valid)
rm "$RESCUE"

echo "Ramdisk built: $(du -sh "$RAMDISK" | cut -f1)"
