#!/bin/sh
set -e

OUTPUT_PATH="$1"
ARCH="${ARCH:-x86_64}"

# Copy binaries from host build into our root
mkdir -p /build/root/bin
cp -v /host/build/guests/linux/rootfs/${ARCH}/bin/* /build/root/bin/

mkdir -p "$(dirname "/outputs/${OUTPUT_PATH}")"

# Build the initramfs
cd /build/root
find . | cpio -o --format=newc > /outputs/${OUTPUT_PATH}

# Deploy it using the standard deploy script
/usr/local/bin/deploy.sh ${OUTPUT_PATH}
