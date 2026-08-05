#!/bin/sh
set -eu

ROOT=$1
KERNEL_DIR=$ROOT/boot/kernel

# installworld includes a complete native development environment. qemount
# builds on the host, so none of it belongs in the runtime appliance.
rm -rf \
    "$ROOT/build" \
    "$ROOT/usr/include" \
    "$ROOT/usr/libexec/binutils227" \
    "$ROOT/usr/libexec/binutils234" \
    "$ROOT/usr/libexec/gcc47" \
    "$ROOT/usr/libexec/gcc80" \
    "$ROOT/usr/libdata" \
    "$ROOT/usr/share"

find "$ROOT/usr/lib" -type f \
    \( -name '*.a' -o -name '*.la' -o -name '*.o' \) -delete

# The generic kernel contains the QEMU storage devices and DragonFly's native
# filesystems. Keep only the modules which add tested filesystem support.
for module in \
    ext2fs.ko \
    libiconv.ko \
    ntfs.ko \
    ntfs_iconv.ko \
    udf.ko
do
    test -f "$KERNEL_DIR/$module"
done

find "$KERNEL_DIR" -mindepth 1 -maxdepth 1 -type f \
    ! -name kernel \
    ! -name ext2fs.ko \
    ! -name libiconv.ko \
    ! -name ntfs.ko \
    ! -name ntfs_iconv.ko \
    ! -name udf.ko \
    -delete

# nrelease presentation files are useful on an installation CD, not in a
# serial filesystem appliance.
rm -rf "$ROOT/autorun"
rm -f \
    "$ROOT/README" \
    "$ROOT/README.USB" \
    "$ROOT/autorun.bat" \
    "$ROOT/autorun.inf" \
    "$ROOT/autorun.pif" \
    "$ROOT/cpignore" \
    "$ROOT/dflybsd.ico" \
    "$ROOT/index.html"

# Fail here rather than publish an image which cannot exercise the two native
# filesystems used by the test-data builders.
for path in \
    bin/cat \
    bin/cp \
    bin/mkdir \
    bin/sh \
    sbin/init \
    sbin/mount \
    sbin/mount_hammer \
    sbin/mount_hammer2 \
    sbin/newfs_hammer \
    sbin/newfs_hammer2 \
    sbin/shutdown \
    sbin/umount
do
    test -e "$ROOT/$path"
done
