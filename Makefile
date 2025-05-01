# Makefile for QEMU rootless microVM project

ARCH := x86_64
KERNEL_VERSION := 6.5
BUSYBOX_VERSION := 1.36.1

KERNEL_IMAGE := build/linux/linux-$(KERNEL_VERSION)/arch/$(ARCH)/boot/bzImage
INITRAMFS_IMAGE := build/initramfs/initramfs.cpio.gz
ISO_DIR := build/fs/iso9660
ISO_IMAGE := $(ISO_DIR)/rootfs.iso

.PHONY: all build-kernel build-initramfs build-iso run clean

all: build-kernel build-initramfs build-iso

build-kernel:
	@echo "Building Linux kernel for $(ARCH) (version $(KERNEL_VERSION))..."
	@bash scripts/build-kernel.sh $(KERNEL_VERSION) $(ARCH)

build-initramfs: build-kernel
	@echo "Building initramfs with BusyBox and modules (for version $(KERNEL_VERSION))..."
	@bash scripts/build-initramfs.sh $(BUSYBOX_VERSION) $(KERNEL_VERSION)

build-iso:
	@echo "Building minimal ISO9660 image..."
	@bash scripts/build-iso.sh

run: all
	@echo "Launching QEMU microVM..."
	@bash scripts/run-qemu.sh $(ARCH)

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf build
