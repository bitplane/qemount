#!/bin/sh
set -e

NBARCH=$(cat /tmp/nbarch)
DESTDIR="/usr/obj/destdir.$NBARCH"

echo "Building NetBSD ramdisk for $ARCH..."

# Create ramdisk directory structure
mkdir -p /ramdisk/bin /ramdisk/sbin /ramdisk/dev /ramdisk/etc \
         /ramdisk/mnt /ramdisk/tmp /ramdisk/proc /ramdisk/kern

# Copy rescue binary (statically linked crunchgen multicall)
RESCUE="/ramdisk/.rescue"
cp "$DESTDIR/rescue/sh" "$RESCUE"

# Hard link user commands in /bin
for cmd in cat chio chmod cp csh date dd df domainname echo ed expr \
           hostname kill ksh ln ls mkdir mt mv pax tar ps pwd rcmd rcp rm rmdir sh \
           sleep stty sync test "[" bzip2 bunzip2 bzcat ftp grep egrep fgrep \
           zgrep zegrep zfgrep gzip gunzip gzcat zcat kdump ktrace ktruss \
           progress ekermit less more vi ex tetris ldd rescue; do
    ln "$RESCUE" "/ramdisk/bin/$cmd"
done

# Hard link admin commands in /sbin
for cmd in atactl badsect brconfig ccdconfig cgdconfig chown chgrp clri \
           disklabel dkctl dmesg dump rdump dump_lfs rdump_lfs fdisk fsck \
           fsck_ext2fs fsck_ffs fsck_lfs fsck_msdos fsdb fsirand gpt ifconfig \
           init mknod modload modstat modunload \
           mount mount_ados mount_cd9660 mount_efs mount_ext2fs mount_fdesc \
           mount_ffs mount_ufs mount_filecore mount_kernfs mount_lfs mount_msdos \
           mount_nfs mount_ntfs mount_null mount_overlay mount_procfs mount_tmpfs \
           mount_umap mount_union mount_mfs \
           newfs newfs_lfs newfs_msdos ping pppoectl raidctl rcorder reboot halt \
           restore rrestore rndctl route routed savecore scan_ffs scsictl setkey \
           shutdown slattach swapctl swapon sysctl ttyflags tunefs umbctl umount \
           wdogctl veriexecctl wsconsctl chroot dumpfs dumplfs installboot \
           vnconfig vndconfig lfs_cleanerd pdisk ping6 scp ssh slogin; do
    ln "$RESCUE" "/ramdisk/sbin/$cmd"
done

# Rename real init so our script can call it
mv /ramdisk/sbin/init /ramdisk/sbin/init.real

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

# Copy qemount tools from build
if [ -f /host/build/bin/${ARCH}-netbsd/simple9p ]; then
    echo "Adding simple9p..."
    cp -v /host/build/bin/${ARCH}-netbsd/simple9p /ramdisk/bin/
    chmod 755 /ramdisk/bin/simple9p
fi

if [ -f /host/build/bin/${ARCH}-netbsd/socat ]; then
    echo "Adding socat..."
    cp -v /host/build/bin/${ARCH}-netbsd/socat /ramdisk/bin/
    chmod 755 /ramdisk/bin/socat
fi

# Create ramdisk filesystem image (16MB)
/usr/tools/bin/nbmakefs -s 16m -t ffs -o version=1 /ramdisk.fs /ramdisk

# Copy to output
mkdir -p /host/build/bin/qemu/${ARCH}-netbsd/10.0/rootfs
cp /ramdisk.fs /host/build/bin/qemu/${ARCH}-netbsd/10.0/rootfs/ramdisk.fs

echo "Done! Ramdisk: $(du -sh /ramdisk | cut -f1)"
