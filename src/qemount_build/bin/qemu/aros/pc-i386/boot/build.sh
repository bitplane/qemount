#!/bin/sh
set -eu

SOURCE_ARCHIVE=/host/build/sources/aros-qemount.tar.gz
SOURCE_DIR=/work/AROS-qemount
TOOLCHAIN_DIR=/opt/aros-toolchain
PORTS_DIR=/opt/aros-portssources
GUEST_BUILD_DIR=/work/guest-build
OUTPUT_DIR=/host/build/bin/qemu/${ARCH}-aros/boot
BUILD_JOBS=${JOBS:-1}

# Port archives are produced by several upstream systems and can contain owner
# IDs that are not representable in a rootless container's user namespace.
# Archive ownership is irrelevant to the build, so apply the same policy to
# AROS's internal fetch helpers as to the source archive below.
TAR_OPTIONS=--no-same-owner
export TAR_OPTIONS

tar --no-same-owner -xzf "$SOURCE_ARCHIVE" -C /work

mkdir -p "$GUEST_BUILD_DIR"
cd "$GUEST_BUILD_DIR"
"$SOURCE_DIR/configure" \
    --target="$AROS_TARGET" \
    --enable-target-variant="$AROS_VARIANT" \
    --enable-build-type=nightly \
    --enable-ccache \
    --with-portssources="$PORTS_DIR" \
    --with-aros-toolchain-install="$TOOLCHAIN_DIR" \
    --with-aros-toolchain=yes \
    --with-optimization="-Os -fno-defer-pop -mpreferred-stack-boundary=4" \
    --with-theme=AmigaOS3.x \
    --with-iconset=Mason \
    --with-bootloader=grub2

make -j"$BUILD_JOBS"
# The upstream ISO graph still names the pre-2011 kernel-package target.
# Build the current kernel target explicitly until that dependency is fixed
# on the AROS qemount branch and merged upstream.
make -j"$BUILD_JOBS" kernel-link-pc-i386
make -j"$BUILD_JOBS" bootiso-pc-i386

mkdir -p "$OUTPUT_DIR"
cp "distfiles/aros-${AROS_VARIANT}-pc-i386.iso" "$OUTPUT_DIR/aros.iso"
