#!/bin/sh
set -e

BIN_DIR="/host/build/bin/${MOUNTIN_TARGET_ARCH}-netbsd"
SHARE_DIR="/host/build/share/${MOUNTIN_TARGET_ARCH}-netbsd"
OUTPUT=${1:-guest/${MOUNTIN_TARGET_ARCH}-netbsd/10.0/rootfs/ramdisk.fs}
OUTPUT_PATH="/host/build/$OUTPUT"

echo "Building NetBSD ramdisk for $MOUNTIN_TARGET_ARCH..."

# Create ramdisk directory structure
mkdir -p /ramdisk/bin /ramdisk/sbin /ramdisk/dev /ramdisk/etc \
         /ramdisk/libexec /ramdisk/mnt /ramdisk/tmp /ramdisk/proc /ramdisk/kern

# Copy the mountin-specific crunchgen multicall binary.
RESCUE="/ramdisk/.rescue"
cp "$BIN_DIR/mountin-rescue" "$RESCUE"

# Hard link user commands in /bin
for cmd in cat cp dd df expr ls mkdir rm rmdir sh stty sync sort uname; do
    ln "$RESCUE" "/ramdisk/bin/$cmd"
done

# Hard link admin commands in /sbin
for cmd in dkctl ifconfig mount mount_ados mount_cd9660 mount_efs \
           mount_ext2fs mount_ffs mount_ufs mount_filecore mount_hfs mount_lfs \
           mount_msdos mount_ntfs mount_procfs mount_tmpfs mount_udf \
           mount_v7fs halt \
           sysctl umount; do
    ln "$RESCUE" "/ramdisk/sbin/$cmd"
done

ln "$RESCUE" /ramdisk/libexec/lfs_cleanerd

# Remove base rescue copy (all links remain valid)
rm "$RESCUE"

# Copy init scripts and etc files from overlay
cp -v /root/sbin/init /ramdisk/sbin/init
chmod 755 /ramdisk/sbin/init
cp -v /root/init.sh /ramdisk/init.sh
chmod 755 /ramdisk/init.sh
cp -v /root/init.9p /ramdisk/init.9p
chmod 755 /ramdisk/init.9p
cp -v /root/etc/* /ramdisk/etc/
/usr/tools/bin/nbpwd_mkdb -d /ramdisk /ramdisk/etc/master.passwd

# Copy mountin tools from build
case "$OUTPUT" in
*/appliance/*)
    echo "Adding 9d..."
    cp -v "$BIN_DIR/9d" /ramdisk/bin/
    chmod 755 /ramdisk/bin/9d
    ;;
esac

# Let makefs calculate the minimum complete filesystem. Runtime scratch and
# mount points use tmpfs, so the embedded root does not need reserved space.
/usr/tools/bin/nbmakefs -N /ramdisk/etc -s 4194304 \
    -F "$SHARE_DIR/mountin-devices.mtree" \
    -t ffs -o version=1 /ramdisk.fs /ramdisk

# Copy to output
mkdir -p "$(dirname "$OUTPUT_PATH")"
cp /ramdisk.fs "$OUTPUT_PATH"
size=$(stat -c %s /ramdisk.fs)
test "$size" -eq 4194304

echo "Done! Ramdisk: $(du -sh /ramdisk | cut -f1)"
