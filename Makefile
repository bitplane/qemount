# Rootless QEMU MicroVM Makefile

ARCH := x86_64
KERNEL_VERSION := 6.5
BUSYBOX_VERSION := 1.36.1

BUILD_DIR := build
KERNEL_DIR := $(BUILD_DIR)/linux
KERNEL_SRC := $(KERNEL_DIR)/linux-$(KERNEL_VERSION)
KERNEL_IMAGE := $(KERNEL_SRC)/arch/$(ARCH)/boot/bzImage

INITRAMFS_DIR := $(BUILD_DIR)/initramfs
INITRAMFS_IMAGE := $(INITRAMFS_DIR)/initramfs.cpio.gz

ISO_DIR := $(BUILD_DIR)/fs/iso9660
ISO_IMAGE := $(ISO_DIR)/rootfs.iso
ISO_DATA := overlays/iso9660/data

.PHONY: all run clean

all: $(KERNEL_IMAGE) $(INITRAMFS_IMAGE) $(ISO_IMAGE)

$(KERNEL_IMAGE):
	@echo "==> Building Linux kernel $(KERNEL_VERSION) for $(ARCH)..."
	@bash scripts/build-kernel.sh $(KERNEL_VERSION) $(ARCH) $(KERNEL_DIR) $(KERNEL_IMAGE)

$(INITRAMFS_IMAGE): $(KERNEL_IMAGE)
	@echo "==> Building initramfs with BusyBox $(BUSYBOX_VERSION)..."
	@bash scripts/build-initramfs.sh $(BUSYBOX_VERSION) $(KERNEL_VERSION) $(INITRAMFS_IMAGE)

$(ISO_IMAGE):
	@echo "==> Building ISO image..."
	@bash scripts/build-iso.sh $(ARCH) $(ISO_DATA) $(ISO_IMAGE)

run: $(KERNEL_IMAGE) $(INITRAMFS_IMAGE) $(ISO_IMAGE)
	@echo "==> Running QEMU..."
	@bash scripts/run-qemu.sh $(ARCH) $(KERNEL_IMAGE) $(INITRAMFS_IMAGE) $(ISO_IMAGE)

clean:
	@echo "==> Cleaning build output..."
	rm -rf $(BUILD_DIR)
