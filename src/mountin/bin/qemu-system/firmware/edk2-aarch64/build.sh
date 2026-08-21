#!/bin/sh
set -eu

SOURCE=/host/build/sources/qemu-10.2.0.tar.xz
WORK=/work/qemu-10.2.0
OUTPUT=/host/build/bin/qemu-system/firmware/edk2-aarch64-code.fd
MOUNTIN_BUILD_JOBS=${MOUNTIN_BUILD_JOBS:-1}

rm -rf "$WORK"
mkdir -p "$WORK" "${OUTPUT%/*}"
tar -xf "$SOURCE" -C "$WORK" --strip-components=1

cd "$WORK/roms"
python3 edk2-build.py \
    --config /edk2-build.config \
    --jobs "$MOUNTIN_BUILD_JOBS" \
    --match armvirt.aa64 \
    --version-override qemu-10.2.0

install -m 644 \
    Build/ArmVirtQemu-AARCH64/DEBUG_GCC5/FV/QEMU_EFI.fd \
    "$OUTPUT"
