# guest/linux-6.11/Makefile
# Modular build system for the linux-6.11 guest

# Main Targets - define before includes to set the default target
.PHONY: all image downloads clean distclean

# Default target
all: image

include mk/common.mk
include mk/downloads.mk
include mk/kernel.mk
include mk/busybox.mk
include mk/rootfs.mk  
include mk/outputs.mk

# Main guest image target
image: downloads $(FINAL_KERNEL) $(FINAL_INITRAMFS) $(FINAL_RUN_SH) $(FINAL_META_CONF)
	@echo "Guest image built successfully in $(OUTPUT_DIR)"

# Clean target - we don't delete configs as they're automatically 
# regenerated when needed and cached for faster builds
clean:
	rm -rf "$(STAGING_ROOTFS_DIR)"
	rm -f "$(ROOTFS_STAGING_STAMP)"
	rm -f "$(BUSYBOX_INSTALL_STAMP)"
	rm -f "$(KERNEL_BUILD_STAMP)"
	@echo "Clean completed"

# Full clean that removes all artifacts including cached configs
distclean: clean
	rm -f "$(BUSYBOX_CONFIG)" "$(BUSYBOX_DEFAULT_CONFIG)"
	rm -rf "$(BUSYBOX_INSTALL_DIR)"
	rm -rf "$(KERNEL_BUILD_DIR)"
	@echo "Distclean completed"