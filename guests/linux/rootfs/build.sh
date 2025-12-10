#!/bin/sh
set -e

OUTPUT_PATH="$1"
ARCH="${ARCH:-x86_64}"

# Copy binaries from host build into our root
mkdir -p /build/root/bin
cp -v /host/build/guests/linux/rootfs/${ARCH}/bin/* /build/root/bin/

# Calculate size and create ext2 image
SIZE=$(du -sm /build/root | cut -f1)
IMG_SIZE=$(( SIZE + 4 ))M  # Add 4MB padding

truncate -s "$IMG_SIZE" /tmp/boot.img
mke2fs -t ext2 -d /build/root /tmp/boot.img

# Deploy using standard deploy script
mkdir -p "$(dirname "/outputs/${OUTPUT_PATH}")"
cp /tmp/boot.img "/outputs/${OUTPUT_PATH}"
/usr/local/bin/deploy.sh ${OUTPUT_PATH}
