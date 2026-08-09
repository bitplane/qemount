#!/bin/sh
set -eu

test "$OUTPUT_ARCH" = x86_64

WORLD=/work/world
ROOT=/work/root
OUTPUT_DIR=/host/build/bin/qemu/${OUTPUT_PLATFORM}/6.4.2/system
TARGET_INSTALL="${DRAGONFLY_OBJ}/usr/src/btools_x86_64/usr/bin/install -N ${DRAGONFLY_SRC}/etc"

cd "$DRAGONFLY_SRC"

world_make()
{
    MAKEOBJDIRPREFIX="${DRAGONFLY_OBJ}/usr/src/world_x86_64" \
    OBJTREE="$DRAGONFLY_OBJ" \
    MACHINE_ARCH=x86_64 \
    MACHINE=x86_64 \
    MACHINE_PLATFORM=pc64 \
    LC_ALL=C \
    OBJFORMAT_PATH="${DRAGONFLY_OBJ}/usr/src/ctools_x86_64_x86_64" \
    HOST_CCVER=gcc80 \
    CCVER=gcc80 \
    LDVER=ld.bfd \
    BINUTILSVER=binutils234 \
    WORLDBUILD=1 \
    DESTDIR="${DRAGONFLY_OBJ}/usr/src/world_x86_64" \
    _SHLIBDIRPREFIX="${DRAGONFLY_OBJ}/usr/src/world_x86_64" \
    M4="${DRAGONFLY_OBJ}/usr/src/btools_x86_64/usr/bin/m4" \
    PATH="${DRAGONFLY_OBJ}/usr/src/ctools_x86_64_x86_64/usr/sbin:${DRAGONFLY_OBJ}/usr/src/ctools_x86_64_x86_64/usr/bin:${DRAGONFLY_OBJ}/usr/src/ctools_x86_64_x86_64/sbin:${DRAGONFLY_OBJ}/usr/src/ctools_x86_64_x86_64/bin:${DRAGONFLY_OBJ}/usr/src/btools_x86_64/usr/sbin:${DRAGONFLY_OBJ}/usr/src/btools_x86_64/usr/bin:${DRAGONFLY_OBJ}/usr/src/btools_x86_64/sbin:${DRAGONFLY_OBJ}/usr/src/btools_x86_64/bin:/usr/local/bin:/usr/pkg/bin" \
        /usr/bin/bmake "$@"
}

world_make -C "$DRAGONFLY_SRC/stand/boot/libstand32" libstand32.a
world_make -C "$DRAGONFLY_SRC/stand/boot/pc32/loader" clean
world_make -C "$DRAGONFLY_SRC/stand/boot/pc32/loader" \
    MACHINE_ARCH=i386 \
    MACHINE_PLATFORM=pc32 \
    REALLY_X86_64=true \
    loader

bmake -j"${JOBS}" \
    KERNCONF=QEMOUNT \
    MODULES_OVERRIDE="vfs/ext2fs vfs/ntfs vfs/udf libiconv" \
    MACHINE=x86_64 \
    MACHINE_ARCH=x86_64 \
    MACHINE_PLATFORM=pc64 \
    NOCLEAN=1 \
    TARGET_ARCH=x86_64 \
    TARGET_PLATFORM=pc64 \
    WORLD_VERSION=600401 \
    buildkernel

rm -rf "$WORLD" "$ROOT"
mkdir -p "$WORLD" "$ROOT"

bmake \
    DESTDIR="$WORLD" \
    MACHINE=x86_64 \
    MACHINE_ARCH=x86_64 \
    MACHINE_PLATFORM=pc64 \
    TARGET_ARCH=x86_64 \
    TARGET_PLATFORM=pc64 \
    WORLD_VERSION=600401 \
    INSTALL="$TARGET_INSTALL" \
    NO_GAMES=1 \
    NO_INITRD=1 \
    NO_SHARE=1 \
    installworld

bmake \
    DESTDIR="$WORLD" \
    KERNCONF=QEMOUNT \
    MODULES_OVERRIDE="vfs/ext2fs vfs/ntfs vfs/udf libiconv" \
    MACHINE=x86_64 \
    MACHINE_ARCH=x86_64 \
    MACHINE_PLATFORM=pc64 \
    TARGET_ARCH=x86_64 \
    TARGET_PLATFORM=pc64 \
    WORLD_VERSION=600401 \
    INSTALL="$TARGET_INSTALL" \
    INSTALLSTRIPPED=1 \
    reinstallkernel

/build/assemble-root.py "$WORLD" "$ROOT" /build/runtime-files.txt
mkdir -p "$ROOT/etc"
install -m 644 /build/loader.conf "$ROOT/boot/loader.conf"
install -m 644 /build/dloader.rc "$ROOT/boot/dloader.rc"
install -m 755 /build/qemount-rc "$ROOT/etc/rc"
install -m 644 "$DRAGONFLY_SRC/etc/login.conf" "$ROOT/etc/login.conf"
install -m 644 "$DRAGONFLY_SRC/initrd/etc/termcap" "$ROOT/etc/termcap"
mkdir -p "$ROOT/etc/defaults"
install -m 644 "$DRAGONFLY_SRC/etc/defaults/uuids" "$ROOT/etc/defaults/uuids"

for directory in dev mnt proc tmp var var/run; do
    mkdir -p "$ROOT/$directory"
done

for path in \
    boot/cdboot \
    boot/loader \
    boot/kernel/kernel \
    bin/sh \
    sbin/init \
    sbin/mount \
    sbin/mount_hammer \
    sbin/mount_hammer2 \
    sbin/newfs_hammer \
    sbin/newfs_hammer2 \
    sbin/umount
do
    test -e "$ROOT/$path"
done

mkdir -p "$OUTPUT_DIR"
xorriso -as mkisofs \
    -R \
    -J \
    -b boot/cdboot \
    -no-emul-boot \
    -V QEMOUNT_DRAGONFLY \
    -o "$OUTPUT_DIR/dragonfly.iso" \
    "$ROOT"

size=$(stat -c %s "$OUTPUT_DIR/dragonfly.iso")
limit=$((16 * 1024 * 1024))
if [ "$size" -gt "$limit" ]; then
    echo "DragonFly appliance exceeds 16 MiB: $size bytes" >&2
    exit 1
fi
