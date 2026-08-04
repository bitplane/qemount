#!/bin/sh
set -eu

test "$OUTPUT_ARCH" = x86_64

ROOT=/work/root
OUTPUT_DIR=/host/build/bin/qemu/${OUTPUT_PLATFORM}/6.4.2/system
TARGET_INSTALL="${DRAGONFLY_OBJ}/usr/src/btools_x86_64/usr/bin/install -N ${DRAGONFLY_SRC}/etc"

cd "$DRAGONFLY_SRC"

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

mkdir -p "$OUTPUT_DIR"
xorriso -as mkisofs \
    -R \
    -J \
    -b boot/cdboot \
    -no-emul-boot \
    -V QEMOUNT_DRAGONFLY \
    -o "$OUTPUT_DIR/dragonfly.iso" \
    "$ROOT"
