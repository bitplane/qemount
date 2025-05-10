#!/bin/sh
set -e

OUTPUT_PATH="$1"
ARCH="${ARCH:-x86_64}"

# Copy binaries from host build into our root
mkdir -p /build/root/bin
cp -v /host/build/guests/linux-6.11/rootfs/${ARCH}/bin/busybox /build/root/bin/
cp -v /host/build/guests/linux-6.11/rootfs/${ARCH}/bin/dropbearmulti /build/root/bin/
cp -v /host/build/guests/linux-6.11/rootfs/${ARCH}/bin/u9fs /build/root/bin/

mkdir -p "$(dirname "/outputs/${OUTPUT_PATH}")"

# Build the initramfs
cd /build/root
find . | cpio -o --format=newc | gzip -9 > /outputs/${OUTPUT_PATH}

# Deploy it using the standard deploy script
/usr/local/bin/deploy.sh ${OUTPUT_PATH}
