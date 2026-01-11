#!/bin/bash
set -e

# QEMU disk builder - boots Linux VM to duplicate files between filesystems
# Requires kernel and rootfs.img in /host/build

HOST_ARCH="${HOST_ARCH:-x86_64}"
KERNEL_VERSION=$(echo "$META" | jq -r '.kernel // "6.17"')
KERNEL="/host/build/bin/qemu/linux-${HOST_ARCH}/${KERNEL_VERSION}/boot/kernel"
ROOTFS="/host/build/bin/qemu/linux-${HOST_ARCH}/${KERNEL_VERSION}/boot/rootfs.img"

# Loop over all outputs in META.provides
for output in $(echo "$META" | jq -r '.provides | keys[]'); do
    base_name=$(basename "$output" | sed 's/\.[^.]*$//')
    tar_path="/host/build/data/templates/${base_name}.tar"
    output_path="/host/build/$output"

    echo "Building: $output"

    # Extract template
    rm -rf /tmp/template
    mkdir -p /tmp/template
    tar -xf "$tar_path" -C /tmp/template

    # Create target filesystem (buildfs.sh may modify /tmp/template)
    /build/buildfs.sh /tmp/template /tmp/target.img

    # Create source ext2 from template (after buildfs.sh modifications)
    size=$(du -sm /tmp/template | cut -f1)
    img_size=$(( size + 4 ))
    truncate -s "${img_size}M" /tmp/source.ext2
    mke2fs -t ext2 -d /tmp/template /tmp/source.ext2

    # Map architecture to QEMU binary
    case "$HOST_ARCH" in
        x86_64) QEMU_BIN="qemu-system-x86_64" ;;
        aarch64|arm64) QEMU_BIN="qemu-system-aarch64" ;;
        *) echo "Unsupported architecture: $HOST_ARCH"; exit 1 ;;
    esac

    # Boot QEMU to duplicate files from source to target
    timeout 120 "$QEMU_BIN" \
        -m 256 \
        -kernel "$KERNEL" \
        -drive "file=$ROOTFS,format=raw,if=virtio,readonly=on" \
        -drive "file=/tmp/source.ext2,format=raw,if=virtio,readonly=on" \
        -drive "file=/tmp/target.img,format=raw,if=virtio" \
        -append "root=/dev/vda ro console=ttyS0 mode=duplicate quiet" \
        -nographic \
        -no-reboot

    # Copy result to output
    mkdir -p "$(dirname "$output_path")"
    cp /tmp/target.img "$output_path"

    echo "Built: $output"
done
