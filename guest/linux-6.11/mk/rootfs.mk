# mk/rootfs.mk - Rootfs and initramfs creation

# Rootfs & Initramfs 
ROOTFS_STAGING_STAMP := $(STAGING_ROOTFS_DIR)/.rootfs_prepared
BUILD_ROOTFS_SH := $(SCRIPT_DIR)/build_rootfs.sh
BUILD_9P_SH := $(SCRIPT_DIR)/build_9p.sh
BUILD_INITRAMFS_SH := $(SCRIPT_DIR)/build_initramfs.sh

# Create staging rootfs
$(ROOTFS_STAGING_STAMP): $(SOURCE_ROOTFS_DIR)/init $(BUSYBOX_INSTALL_STAMP) $(BUILD_9P_SH) $(BUILD_ROOTFS_SH)
	$(BUILD_ROOTFS_SH) \
		"$(TARGET_ARCH)" \
		"$(SOURCE_ROOTFS_DIR)" \
		"$(STAGING_ROOTFS_DIR)" \
		"$(CACHE_DIR)" \
		"$(BUSYBOX_INSTALL_DIR)" \
	&& touch $@

# Build initramfs
$(FINAL_INITRAMFS): $(KERNEL_BUILD_STAMP) $(ROOTFS_STAGING_STAMP) $(BUILD_INITRAMFS_SH)
	mkdir -p "$(OUTPUT_DIR)"
	$(BUILD_INITRAMFS_SH) \
		"$(KERNEL_VERSION)" \
		"$(KERNEL_ARCH)" \
		"$(KERNEL_BUILD_DIR)" \
		"$(STAGING_ROOTFS_DIR)" \
		"$@"