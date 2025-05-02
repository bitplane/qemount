#!/bin/bash
#
# guest/linux-6.11/scripts/build_run_script.sh
#
# Generates the final run.sh script from a template by substituting placeholders.
#
# Usage:
# ./build_run_script.sh <TEMPLATE_PATH> <FINAL_RUN_SH_PATH> <KERNEL_ARCH> \
#                       <FINAL_KERNEL_NAME> <TARGET_ARCH>

set -euo pipefail

# --- Argument Parsing ---
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <TEMPLATE_PATH> <FINAL_RUN_SH_PATH> <KERNEL_ARCH> <FINAL_KERNEL_NAME> <TARGET_ARCH>" >&2
    exit 1
fi

TEMPLATE_PATH="$1"          # Relative path to run.sh.template
FINAL_RUN_SH_PATH_REL="$2"  # Relative or absolute path for final run.sh
KERNEL_ARCH="$3"            # e.g., x86_64, arm64
FINAL_KERNEL_NAME="$4"      # e.g., kernel
TARGET_ARCH="$5"            # e.g., amd64, arm64

# --- Resolve Paths ---
# Assumes this script is run from the guest/linux-6.11 directory by make -C
FINAL_RUN_SH_PATH=$(realpath "$FINAL_RUN_SH_PATH_REL")
FINAL_RUN_SH_DIR=$(dirname "$FINAL_RUN_SH_PATH")

# --- Check Prerequisites ---
if [ ! -f "$TEMPLATE_PATH" ]; then
    echo "Error: Template file '$TEMPLATE_PATH' not found." >&2
    exit 1
fi
command -v sed >/dev/null 2>&1 || { echo >&2 "Error: sed command not found."; exit 1; }

# --- Ensure Output Directory Exists ---
mkdir -p "$FINAL_RUN_SH_DIR"

# --- Determine QEMU Command ---
QEMU_CMD=$(which "qemu-system-${KERNEL_ARCH}" 2>/dev/null || echo "qemu-system-${KERNEL_ARCH}")
echo "Using QEMU command: $QEMU_CMD"

# --- Perform Substitutions ---
echo "Generating $FINAL_RUN_SH_PATH from $TEMPLATE_PATH..."
sed -e "s|@@QEMU_COMMAND@@|${QEMU_CMD}|g" \
    -e "s|@@KERNEL_FILENAME@@|${FINAL_KERNEL_NAME}|g" \
    -e "s|@@INITRAMFS_FILENAME@@|initramfs.cpio.gz|g" \
    -e "s|@@TARGET_ARCH@@|${TARGET_ARCH}|g" \
    -e "s|@@KERNEL_ARCH@@|${KERNEL_ARCH}|g" \
    "$TEMPLATE_PATH" > "$FINAL_RUN_SH_PATH"

if [ $? -ne 0 ]; then
    echo "Error: sed command failed during run.sh generation." >&2
    # rm -f "$FINAL_RUN_SH_PATH" # Optionally remove partial file
    exit 1
fi

# --- Make Executable ---
chmod +x "$FINAL_RUN_SH_PATH"

echo "Successfully generated executable run script: $FINAL_RUN_SH_PATH"
exit 0
