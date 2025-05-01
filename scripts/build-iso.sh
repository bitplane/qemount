#!/bin/bash

# Script to build a minimal ISO9660 image for QEMU guest
set -eux

ARCH=${ARCH:-x86_64}
ISO_DIR=build/fs/iso9660
DATA_DIR=overlays/iso9660/data
ISO_OUT=$ISO_DIR/rootfs.iso

mkdir -p "$ISO_DIR"

# Use dummy data if none provided
if [ ! -d "$DATA_DIR" ]; then
  mkdir -p "$DATA_DIR"
  echo "Hello from afuse99p" > "$DATA_DIR/hello.txt"
fi

# Create ISO image
genisoimage -quiet -o "$ISO_OUT" -R "$DATA_DIR"
echo "ISO created at $ISO_OUT"
