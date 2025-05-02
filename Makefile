ARCH                  := x86_64
FS                    := iso9660
KERNEL_VERSION        := 6.11
BUSYBOX_VERSION       := 1.36.1

BUILD_DIR             := build
KERNEL_DIR            := $(BUILD_DIR)/linux
KERNEL_SRC            := $(KERNEL_DIR)/linux-$(KERNEL_VERSION)
KERNEL_IMAGE          := $(KERNEL_SRC)/arch/$(ARCH)/boot/bzImage

INITRAMFS_DIR         := $(BUILD_DIR)/initramfs/$(ARCH)/$(FS)
BUSYBOX_TARBALL       := $(BUILD_DIR)/initramfs/busybox-$(BUSYBOX_VERSION).tar.bz2
BUSYBOX_SRC           := $(INITRAMFS_DIR)/busybox-$(BUSYBOX_VERSION)
BUSYBOX_INSTALL       := $(BUSYBOX_SRC)/_install

INITRAMFS_IMAGE       := $(INITRAMFS_DIR)/initramfs.cpio.gz
ROOTFS_DIR            := $(INITRAMFS_DIR)/rootfs

OVERLAY_DIR           := overlays
SHARED_OVERLAY        := $(wildcard $(OVERLAY_DIR)/shared/*)
FS_OVERLAY            := $(wildcard $(OVERLAY_DIR)/$(FS)/*)
CONFIG_INITRAMFS_PATH := config/initramfs/$(ARCH)/$(FS)/busybox.config
CONFIG_KERNEL_PATH    := config/kernel/$(ARCH)/minimal.config

ISO_DIR               := $(BUILD_DIR)/fs/$(FS)
ISO_IMAGE             := $(ISO_DIR)/rootfs.iso
ISO_DATA              := $(OVERLAY_DIR)/$(FS)/data

BUSYBOX_BUILD_STAMP   := $(INITRAMFS_DIR)/.busybox-built
INITRAMFS_BUILD_STAMP := $(INITRAMFS_DIR)/.initramfs-built


.PHONY: all clean run

all: $(KERNEL_IMAGE) $(INITRAMFS_IMAGE) $(ISO_IMAGE)

$(KERNEL_IMAGE): $(CONFIG_KERNEL_PATH) scripts/build-kernel.sh
	@echo "==> Building Linux kernel $(KERNEL_VERSION) for $(ARCH)..."
	bash scripts/build-kernel.sh $(KERNEL_VERSION) $(ARCH) $(KERNEL_DIR) $(KERNEL_IMAGE)

$(BUSYBOX_TARBALL):
	mkdir -p $(INITRAMFS_DIR)
	wget -O $@ "https://busybox.net/downloads/busybox-$(BUSYBOX_VERSION).tar.bz2"

$(BUSYBOX_INSTALL): $(BUSYBOX_TARBALL) $(CONFIG_INITRAMFS_PATH)
	@echo "==> Building BusyBox..."
	bash scripts/build-busybox.sh $(BUSYBOX_VERSION) $(ARCH) $(CONFIG_INITRAMFS_PATH) $(BUSYBOX_SRC) $(BUSYBOX_TARBALL)
	touch $(BUSYBOX_BUILD_STAMP)

$(INITRAMFS_IMAGE): $(INITRAMFS_BUILD_STAMP)


$(INITRAMFS_BUILD_STAMP): $(BUSYBOX_INSTALL) $(SHARED_OVERLAY) $(FS_OVERLAY) scripts/build-initramfs.sh
	@echo "==> Building initramfs..."
	bash scripts/build-initramfs.sh $(ARCH) $(BUSYBOX_VERSION) $(KERNEL_VERSION) $(INITRAMFS_IMAGE)
	touch $@

$(ISO_IMAGE): $(wildcard $(ISO_DATA)/*) scripts/build-iso.sh
	@echo "==> Building ISO image..."
	bash scripts/build-iso.sh $(ARCH) $(ISO_DATA) $(ISO_IMAGE)

$(CONFIG_INITRAMFS_PATH):
	bash scripts/gen-busybox-config.sh $(ARCH) $(FS) $(BUSYBOX_VERSION)

$(CONFIG_KERNEL_PATH):
	bash scripts/gen-kernel-config.sh $(ARCH)


run: $(KERNEL_IMAGE) $(INITRAMFS_IMAGE) $(ISO_IMAGE)
	@echo "==> Running QEMU..."
	bash scripts/run-qemu.sh $(ARCH) $(KERNEL_IMAGE) $(INITRAMFS_IMAGE) $(ISO_IMAGE)

clean:
	rm -rf $(BUILD_DIR)
