# mk/initramfs.mk - Build initramfs from staged rootfs

FINAL_INITRAMFS := $(OUTPUT_DIR)/initramfs.cpio.gz
INITRAMFS_STAMP := $(FINAL_INITRAMFS).stamp

.PHONY: initramfs
initramfs: $(FINAL_INITRAMFS)

$(FINAL_INITRAMFS): $(ROOTFS_STAGING_STAMP) $(KERNEL_BUILD_STAMP) scripts/build_initramfs.sh
	@echo "[initramfs] generating compressed initramfs..."
	scripts/build_initramfs.sh \
		"$(KERNEL_VERSION)" \
		"$(KERNEL_ARCH)" \
		"$(KERNEL_BUILD_DIR)" \
		"$(STAGING_ROOTFS_DIR)" \
		"$(FINAL_INITRAMFS)"
