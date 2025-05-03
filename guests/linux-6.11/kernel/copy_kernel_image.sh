#!/bin/bash
set -euo pipefail

KERNEL_BUILD_DIR="$1"
KERNEL_ARCH="$2"
FINAL_KERNEL_PATH="$3"

# Find kernel image based on architecture
case "$KERNEL_ARCH" in
    x86_64) KERNEL_IMAGE_NAME="bzImage" ;;
    arm64)
        if [ -f "$KERNEL_BUILD_DIR/arch/$KERNEL_ARCH/boot/Image.gz" ]; then
            KERNEL_IMAGE_NAME="Image.gz"
        else
            KERNEL_IMAGE_NAME="Image"
        fi ;;
    arm) KERNEL_IMAGE_NAME="zImage" ;;
    riscv)
        if [ -f "$KERNEL_BUILD_DIR/arch/$KERNEL_ARCH/boot/Image.gz" ]; then
            KERNEL_IMAGE_NAME="Image.gz"
        else
            KERNEL_IMAGE_NAME="Image"
        fi ;;
    *)
        if [ -f "$KERNEL_BUILD_DIR/arch/$KERNEL_ARCH/boot/Image" ]; then
            KERNEL_IMAGE_NAME="Image"
        else
            KERNEL_IMAGE_NAME="../vmlinux"
        fi ;;
esac

# Set source path
if [[ "$KERNEL_IMAGE_NAME" == "../vmlinux" ]]; then
    KERNEL_IMAGE_SOURCE="$KERNEL_BUILD_DIR/vmlinux"
else
    KERNEL_IMAGE_SOURCE="$KERNEL_BUILD_DIR/arch/$KERNEL_ARCH/boot/$KERNEL_IMAGE_NAME"
fi

# Copy kernel image
mkdir -p "$(dirname "$FINAL_KERNEL_PATH")"
cp "$KERNEL_IMAGE_SOURCE" "$FINAL_KERNEL_PATH"

exit 0