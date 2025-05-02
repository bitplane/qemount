#!/bin/bash
#
# guest/linux-6.11/scripts/copy_kernel_image.sh
#
# Finds the conventional kernel image file within a kernel build directory
# based on architecture and copies it to the specified final destination.
#
# Usage:
# ./copy_kernel_image.sh <KERNEL_BUILD_DIR> <KERNEL_ARCH> <FINAL_KERNEL_PATH>

set -euo pipefail

# --- Argument Parsing ---
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <KERNEL_BUILD_DIR> <KERNEL_ARCH> <FINAL_KERNEL_PATH>" >&2
    exit 1
fi

KERNEL_BUILD_DIR="$1" # Absolute path to kernel build artifacts (O= dir)
KERNEL_ARCH="$2"      # e.g., x86_64, arm64, arm, riscv
FINAL_KERNEL_PATH="$3" # Absolute path for the final output kernel file

# --- Determine Conventional Kernel Filename ---
KERNEL_IMAGE_NAME=""
case "$KERNEL_ARCH" in
    x86_64)
        KERNEL_IMAGE_NAME="bzImage"
        ;;
    arm64)
        KERNEL_IMAGE_NAME="Image.gz" # Sometimes just Image, check both? Prefer compressed.
        # Check if Image.gz exists, otherwise fallback to Image
        if [ ! -f "$KERNEL_BUILD_DIR/arch/$KERNEL_ARCH/boot/$KERNEL_IMAGE_NAME" ] && \
           [ -f "$KERNEL_BUILD_DIR/arch/$KERNEL_ARCH/boot/Image" ]; then
             KERNEL_IMAGE_NAME="Image"
        fi
        ;;
    arm)
        KERNEL_IMAGE_NAME="zImage"
        ;;
    riscv) # Kernel build uses 'riscv' for ARCH
        KERNEL_IMAGE_NAME="Image.gz"
        # Check if Image.gz exists, otherwise fallback to Image
         if [ ! -f "$KERNEL_BUILD_DIR/arch/$KERNEL_ARCH/boot/$KERNEL_IMAGE_NAME" ] && \
           [ -f "$KERNEL_BUILD_DIR/arch/$KERNEL_ARCH/boot/Image" ]; then
             KERNEL_IMAGE_NAME="Image"
        fi
        ;;
    *)
        # Default guess for unknown arches - might need adjustment
        echo "Warning: Unknown KERNEL_ARCH '$KERNEL_ARCH'. Defaulting to 'Image' or 'vmlinux'." >&2
        if [ -f "$KERNEL_BUILD_DIR/arch/$KERNEL_ARCH/boot/Image" ]; then
            KERNEL_IMAGE_NAME="Image"
        elif [ -f "$KERNEL_BUILD_DIR/vmlinux" ]; then
             # Fallback for some architectures that don't put it in arch/boot
             KERNEL_IMAGE_NAME="../vmlinux" # Path relative to arch/<arch>/boot
        else
            echo "Error: Cannot determine kernel image name for arch '$KERNEL_ARCH'." >&2
            exit 1
        fi
        ;;
esac

# --- Construct Source Path ---
KERNEL_IMAGE_SOURCE="$KERNEL_BUILD_DIR/arch/$KERNEL_ARCH/boot/$KERNEL_IMAGE_NAME"

# Handle the vmlinux fallback case where the path is different
if [[ "$KERNEL_IMAGE_NAME" == "../vmlinux" ]]; then
    KERNEL_IMAGE_SOURCE="$KERNEL_BUILD_DIR/vmlinux"
fi


# --- Check if Source Exists ---
if [ ! -f "$KERNEL_IMAGE_SOURCE" ]; then
    echo "Error: Kernel image source file not found at '$KERNEL_IMAGE_SOURCE'" >&2
    echo "(Looked for '$KERNEL_IMAGE_NAME' based on arch '$KERNEL_ARCH')" >&2
    exit 1
fi

# --- Ensure Output Directory Exists ---
FINAL_DIR=$(dirname "$FINAL_KERNEL_PATH")
mkdir -p "$FINAL_DIR"

# --- Copy the File ---
echo "Copying '$KERNEL_IMAGE_SOURCE' to '$FINAL_KERNEL_PATH'..."
cp "$KERNEL_IMAGE_SOURCE" "$FINAL_KERNEL_PATH"

if [ $? -ne 0 ]; then
    echo "Error: Failed to copy kernel image." >&2
    exit 1
fi

echo "Kernel image copied successfully."
exit 0
