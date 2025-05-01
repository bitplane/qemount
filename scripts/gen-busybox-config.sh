#!/bin/bash
set -euo pipefail

ARCH=$1
FS=$2
BUSYBOX_VERSION=$3
CONFIG=config/initramfs/$ARCH/$FS/busybox.config
SHARED=config/initramfs/$ARCH/busybox.shared.config
TARBALL=build/initramfs/$ARCH/$FS/busybox-$BUSYBOX_VERSION.tar.bz2
SRC=build/initramfs/$ARCH/$FS/busybox-$BUSYBOX_VERSION

mkdir -p "$(dirname "$CONFIG")"

if [ -f "$CONFIG" ]; then
    echo "BusyBox config exists: $CONFIG"
    touch "$CONFIG"
    exit 0
fi

if [ -f "$SHARED" ]; then
    echo "Copying shared BusyBox config to $CONFIG"
    cp "$SHARED" "$CONFIG"
else
    echo "ERROR: No config found at $CONFIG or shared fallback at $SHARED" >&2
    exit 1
fi
