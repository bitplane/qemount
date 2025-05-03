# mk/kernel.mk - Kernel build

# Kernel Config
FILESYSTEMS_CONFIG := config/filesystems.config
ARCH_KERNEL_CONFIG := config/kernel.$(KERNEL_ARCH).config
OPTIONAL_BASE_CONFIG := config/kernel.config
KERNEL_BUILD_STAMP := $(KERNEL_BUILD_DIR)/.kernel_built

# Script paths
BUILD_KERNEL_SH := $(SCRIPT_DIR)/build_kernel.sh
COPY_KERNEL_SH := $(SCRIPT_DIR)/copy_kernel_image.sh

$(KERNEL_BUILD_STAMP): $(KERNEL_TARBALL) $(FILESYSTEMS_CONFIG) $(ARCH_KERNEL_CONFIG) $(OPTIONAL_BASE_CONFIG) $(BUILD_KERNEL_SH)
	$(BUILD_KERNEL_SH) \
		"$(KERNEL_VERSION)" \
		"$(KERNEL_ARCH)" \
		"$(FILESYSTEMS_CONFIG)" \
		"$(ARCH_KERNEL_CONFIG)" \
		"$(CACHE_DIR)" \
		"$(KERNEL_BUILD_DIR)" \
		"$(CROSS_COMPILE)" \
	&& touch $@

$(FINAL_KERNEL): $(KERNEL_BUILD_STAMP) $(COPY_KERNEL_SH)
	mkdir -p "$(OUTPUT_DIR)"
	$(COPY_KERNEL_SH) \
		"$(KERNEL_BUILD_DIR)" \
		"$(KERNEL_ARCH)" \
		"$@"