# guest/linux-6.11/Makefile - Main Makefile for qemount guest

.PHONY: all image downloads clean distclean

# Default target
all: image

# Include Makefile fragments in dependency order
include mk/common.mk
include mk/downloads.mk
include mk/kernel.mk
include mk/busybox.mk
include mk/rootfs.mk
include mk/sshd.mk
include mk/9p.mk
include mk/initramfs.mk
include mk/outputs.mk

# Top-level image build
image: downloads $(FINAL_KERNEL) $(FINAL_INITRAMFS) $(FINAL_RUN_SH) $(FINAL_META_CONF)
	@echo "Guest image built successfully in $(OUTPUT_DIR)"

# Clean build outputs (but leave downloads intact)
clean:
	rm -rf "$(STAGING_ROOTFS_DIR)"
	rm -f "$(ROOTFS_STAGING_STAMP)" "$(SSH_DEPLOY_STAMP)"
	rm -f "$(BUSYBOX_INSTALL_STAMP)"
	rm -f "$(KERNEL_BUILD_STAMP)"
	rm -f "$(FINAL_INITRAMFS)"
	@echo "Clean completed"

# Full cleanup including config and source dirs
distclean: clean
	rm -f "$(BUSYBOX_CONFIG)" "$(BUSYBOX_DEFAULT_CONFIG)"
	rm -rf "$(BUSYBOX_INSTALL_DIR)"
	rm -rf "$(KERNEL_BUILD_DIR)"
	@echo "Distclean completed"
