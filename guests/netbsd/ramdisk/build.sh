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
# User commands in /bin
for cmd in cat chio chmod cp csh date dd df domainname echo ed expr \
           hostname kill ksh ln ls mkdir mt mv pax tar ps pwd rcmd rcp rm rmdir sh \
           sleep stty sync test "[" bzip2 bunzip2 bzcat ftp grep egrep fgrep \
           zgrep zegrep zfgrep gzip gunzip gzcat zcat kdump ktrace ktruss \
           progress ekermit less more vi ex tetris ldd rescue; do
    ln "$RESCUE" "$RAMDISK/bin/$cmd"
done

# Admin commands in /sbin
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
    ln "$RESCUE" "$RAMDISK/sbin/$cmd"
done

# Rename real init so our script can call it if needed
mv "$RAMDISK/sbin/init" "$RAMDISK/sbin/init.real"

# Remove the base rescue copy (all links remain valid)
rm "$RESCUE"

echo "Ramdisk built: $(du -sh "$RAMDISK" | cut -f1)"
