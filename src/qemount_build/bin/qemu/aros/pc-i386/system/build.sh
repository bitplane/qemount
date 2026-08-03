#!/bin/sh
set -eu

SOURCE_ARCHIVE=/host/build/sources/aros-qemount-2026-07-30.tar.gz
SOURCE_DIR=/work/source
TOOLCHAIN_DIR=/opt/aros-toolchain
PORTS_DIR=/host/build/sources/aros-ports
GUEST_BUILD_DIR=/work/guest-build
OUTPUT_DIR=/host/build/bin/qemu/${OUTPUT_ARCH}-aros/system
SDK_OUTPUT=/host/build/lib/${OUTPUT_ARCH}-aros/sdk.tar.gz
BUILD_JOBS=${JOBS:-1}

# Port archives are produced by several upstream systems and can contain owner
# IDs that are not representable in a rootless container's user namespace.
# Archive ownership is irrelevant to the build, so apply the same policy to
# AROS's internal fetch helpers as to the source archive below.
TAR_OPTIONS=--no-same-owner
export TAR_OPTIONS

mkdir -p "$SOURCE_DIR"
tar --no-same-owner -xzf "$SOURCE_ARCHIVE" \
    -C "$SOURCE_DIR" --strip-components=1

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

# Unlike the other fetched build inputs, AROS looks for pci.ids in its
# generated-file directory rather than PORTSSOURCEDIR.
PCI_IDS_DIR="$GUEST_BUILD_DIR/bin/${AROS_TARGET}-${AROS_VARIANT}/gen/rom/hidds/pci"
mkdir -p "$PCI_IDS_DIR"
cp "$PORTS_DIR/pci.ids" "$PCI_IDS_DIR/pci.ids"

make -j"$BUILD_JOBS"
make -j"$BUILD_JOBS" bootiso-pc-i386

mkdir -p "$OUTPUT_DIR"
cp "distfiles/aros-${AROS_VARIANT}-pc-i386.iso" "$OUTPUT_DIR/aros.iso"

mkdir -p "$(dirname "$SDK_OUTPUT")"
tar -czf "$SDK_OUTPUT" \
    -C "$GUEST_BUILD_DIR/bin/${AROS_TARGET}-${AROS_VARIANT}/AROS" \
    Developer
