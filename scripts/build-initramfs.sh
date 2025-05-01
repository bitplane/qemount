#!/bin/bash
set -eux

ARCH=${ARCH:-x86_64}
KERNEL_VERSION=${KERNEL_VERSION:-6.5}
BUSYBOX_VERSION=${BUSYBOX_VERSION:-1.36.1}
INITRAMFS_IMAGE=${INITRAMFS_IMAGE:-build/initramfs/initramfs.cpio.gz}

INITRAMFS_DIR=$(dirname "$INITRAMFS_IMAGE")
ROOTFS_DIR="$INITRAMFS_DIR/rootfs"
BUSYBOX_TARBALL="build/initramfs/busybox-$BUSYBOX_VERSION.tar.bz2"
BUSYBOX_SRC="build/initramfs/busybox-$BUSYBOX_VERSION"
CONFIG_PATH="config/initramfs/$ARCH/busybox.config"

mkdir -p "$ROOTFS_DIR"

# Download BusyBox
if [ ! -f "$BUSYBOX_TARBALL" ]; then
    wget -O "$BUSYBOX_TARBALL" "https://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2"
fi

# Extract and build BusyBox
if [ ! -d "$BUSYBOX_SRC" ]; then
    tar -xf "$BUSYBOX_TARBALL" -C "$(dirname "$BUSYBOX_SRC")"
fi

# Enter BusyBox source directory
pushd "$BUSYBOX_SRC"  # Now in BusyBox source dir
make distclean || true

# Validate and copy BusyBox config
CONFIG_PATH=$(realpath "$OLDPWD/$CONFIG_PATH")
if [ ! -f "$CONFIG_PATH" ]; then
    echo "ERROR: BusyBox config not found at $CONFIG_PATH" >&2
    exit 1
fi
cp "$CONFIG_PATH" .config

make -j"$(nproc)"
make CONFIG_PREFIX="$PWD/_install" install
popd  # Back from BusyBox source dir

# Copy rootfs contents
cp -a "$BUSYBOX_SRC/_install/." "$ROOTFS_DIR/"
mkdir -p "$ROOTFS_DIR"/etc "$ROOTFS_DIR"/dev "$ROOTFS_DIR"/proc "$ROOTFS_DIR"/sys "$ROOTFS_DIR"/tmp
chmod 1777 "$ROOTFS_DIR/tmp"

# Add kernel module if available
KMOD_SRC="build/linux/linux-${KERNEL_VERSION}/fs/isofs/isofs.ko"
if [ -f "$KMOD_SRC" ]; then
    mkdir -p "$ROOTFS_DIR/lib/modules/$KERNEL_VERSION/kernel/fs/isofs"
    cp "$KMOD_SRC" "$ROOTFS_DIR/lib/modules/$KERNEL_VERSION/kernel/fs/isofs/"
fi

# Copy init script
cp overlays/shared/init "$ROOTFS_DIR/init"
chmod +x "$ROOTFS_DIR/init"

# Generate initramfs
OUTFILE="${INITRAMFS_IMAGE%.gz}"
mkdir -p "$(dirname "$OUTFILE")"

pushd "$ROOTFS_DIR"  # Now in rootfs directory
find . | cpio -o --format=newc > "$OLDPWD/$OUTFILE"
popd  # Back from rootfs directory

gzip -f "$OUTFILE"

echo "Initramfs build complete: $INITRAMFS_IMAGE"
