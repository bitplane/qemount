#!/bin/bash

set_qemu_netbsd_arch_profile() {
    local arch=$1
    local boot_artifact=$2

    case "$arch" in
        x86_64)
            QEMU_BIN=qemu-system-x86_64
            QEMU_MACHINE_ARGS=()
            QEMU_BOOT_ARGS=(
                -drive "file=$boot_artifact,format=raw,if=virtio,readonly=on"
            )
            ;;
        aarch64|arm64)
            QEMU_BIN=qemu-system-aarch64
            QEMU_MACHINE_ARGS=(-machine virt -cpu cortex-a57)
            QEMU_BOOT_ARGS=(-kernel "$boot_artifact")
            ;;
        *)
            echo "Unsupported NetBSD architecture: $arch" >&2
            return 1
            ;;
    esac
}
