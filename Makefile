# Rootless QEMU MicroVM Makefile

ARCH := x86_64
KERNEL_VERSION := 6.11
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

OVERLAY_DIR := overlays

CONFIG_INITRAMFS_PATH := config/initramfs/$(ARCH)/busybox.config
CONFIG_KERNEL_PATH := config/kernel/$(ARCH)/minimal.config

.PHONY: all run clean config config-initramfs config-kernel

all: $(KERNEL_IMAGE) $(INITRAMFS_IMAGE) $(ISO_IMAGE)

$(KERNEL_IMAGE): $(CONFIG_KERNEL_PATH) scripts/build-kernel.sh
	@echo "==> Building Linux kernel $(KERNEL_VERSION) for $(ARCH)..."
	@bash scripts/build-kernel.sh $(KERNEL_VERSION) $(ARCH) $(KERNEL_DIR) $(KERNEL_IMAGE)



$(INITRAMFS_IMAGE): $(KERNEL_IMAGE) $(wildcard $(OVERLAY_DIR)/shared/*) $(CONFIG_INITRAMFS_PATH)
	@echo "==> Building initramfs..."
	@bash scripts/build-initramfs.sh $(BUSYBOX_VERSION) $(KERNEL_VERSION) $(INITRAMFS_IMAGE)

$(ISO_IMAGE): $(wildcard $(OVERLAY_DIR)/iso9660/data/*)
	@echo "==> Building ISO image..."
	@bash scripts/build-iso.sh $(ARCH) $(ISO_DATA) $(ISO_IMAGE)

run: $(KERNEL_IMAGE) $(INITRAMFS_IMAGE) $(ISO_IMAGE)
	@echo "==> Running QEMU..."
	@bash scripts/run-qemu.sh $(ARCH) $(KERNEL_IMAGE) $(INITRAMFS_IMAGE) $(ISO_IMAGE)

clean:
	@echo "==> Cleaning build output..."
	rm -rf $(BUILD_DIR)

config: config-initramfs config-kernel

config-initramfs:
	@echo "Creating BusyBox config for $(ARCH)..."
	@mkdir -p $(dir $(CONFIG_INITRAMFS_PATH))
	@if [ ! -f "$(CONFIG_INITRAMFS_PATH)" ]; then \
		tar -xf build/initramfs/busybox-$(BUSYBOX_VERSION).tar.bz2 -C build/initramfs; \
		cd build/initramfs/busybox-$(BUSYBOX_VERSION) >/dev/null; \
		make defconfig; \
		cp .config "$$OLDPWD/$(CONFIG_INITRAMFS_PATH)"; \
	else \
		echo "$(CONFIG_INITRAMFS_PATH) already exists."; \
	fi

config-kernel:
	@echo "Creating minimal kernel config for $(ARCH)..."
	@mkdir -p $(dir $(CONFIG_KERNEL_PATH))
	@if [ ! -f "$(CONFIG_KERNEL_PATH)" ]; then \
		echo "Please create a kernel config manually at $(CONFIG_KERNEL_PATH)"; \
		exit 1; \
	else \
		echo "$(CONFIG_KERNEL_PATH) already exists."; \
	fi
