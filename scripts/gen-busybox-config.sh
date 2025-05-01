#!/bin/bash
set -euo pipefail

ARCH=$1
FS=$2
BUSYBOX_VERSION=$3

CONFIG=config/initramfs/$ARCH/$FS/busybox.config
DEFAULT=config/initramfs/busybox.default.config
TARBALL=build/initramfs/$ARCH/$FS/busybox-$BUSYBOX_VERSION.tar.bz2
SRC=build/initramfs/$ARCH/$FS/busybox-$BUSYBOX_VERSION

mkdir -p "$(dirname "$CONFIG")"

if [ -f "$CONFIG" ]; then
    echo "BusyBox config exists: $CONFIG"
    touch "$CONFIG"
    exit 0
fi

if [ -f "$DEFAULT" ]; then
    echo "Creating BusyBox config from default template: $DEFAULT"
    cp "$DEFAULT" "$CONFIG"
else
    echo "ERROR: Missing default BusyBox config at $DEFAULT" >&2
    exit 1
fi
