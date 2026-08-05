#!/bin/sh
set -eu

test "$OUTPUT_ARCH" = x86_64

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
    MACHINE=x86_64 \
    MACHINE_ARCH=x86_64 \
    MACHINE_PLATFORM=pc64 \
    NOCLEAN=1 \
    TARGET_ARCH=x86_64 \
    TARGET_PLATFORM=pc64 \
    WORLD_VERSION=600401 \
    buildkernel

rm -rf "$ROOT"
mkdir -p "$ROOT"

bmake \
    DESTDIR="$ROOT" \
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

mkdir -p /work/etc-obj
PATH="${DRAGONFLY_OBJ}/usr/src/btools_x86_64/usr/bin:${DRAGONFLY_OBJ}/usr/src/btools_x86_64/usr/sbin:${PATH}" \
bmake -m "$DRAGONFLY_SRC/share/mk" -C "$DRAGONFLY_SRC/etc" \
    MAKEOBJDIRPREFIX=/work/etc-obj \
    DESTDIR="$ROOT" \
    MACHINE=x86_64 \
    MACHINE_ARCH=x86_64 \
    INSTALL="$TARGET_INSTALL" \
    distribution

bmake \
    DESTDIR="$ROOT" \
    MACHINE=x86_64 \
    MACHINE_ARCH=x86_64 \
    MACHINE_PLATFORM=pc64 \
    TARGET_ARCH=x86_64 \
    TARGET_PLATFORM=pc64 \
    WORLD_VERSION=600401 \
    INSTALL="$TARGET_INSTALL" \
    INSTALLSTRIPPED=1 \
    reinstallkernel

cp -a "$DRAGONFLY_SRC/nrelease/root/." "$ROOT/"
sed -i '/^dm_load=/d' "$ROOT/boot/loader.conf"
printf '\nconsole="comconsole"\n' >> "$ROOT/boot/loader.conf"

/build/prune-root.sh "$ROOT"

mkdir -p "$OUTPUT_DIR"
xorriso -as mkisofs \
    -R \
    -J \
    -b boot/cdboot \
    -no-emul-boot \
    -V QEMOUNT_DRAGONFLY \
    -o "$OUTPUT_DIR/dragonfly.iso" \
    "$ROOT"
