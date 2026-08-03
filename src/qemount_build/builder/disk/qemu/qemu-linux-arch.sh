#!/bin/bash

set_qemu_linux_arch_profile() {
    QEMU_MACHINE_ARGS=()

    case "$1" in
        x86_64)
            QEMU_BIN=qemu-system-x86_64
            QEMU_CONSOLE=ttyS0
            ;;
        aarch64|arm64)
            QEMU_BIN=qemu-system-aarch64
            QEMU_MACHINE_ARGS=(-machine virt -cpu cortex-a57)
            QEMU_CONSOLE=ttyAMA0
            ;;
        arm)
            QEMU_BIN=qemu-system-arm
            QEMU_MACHINE_ARGS=(-machine virt -cpu cortex-a15)
            QEMU_CONSOLE=ttyAMA0
            ;;
        *)
            echo "Unsupported architecture: $1" >&2
            return 1
            ;;
    esac
}
