# guest/linux-6.11/Makefile
# Orchestrates guest image build using layered config and staging rootfs.

# --- Input Variables (Expected from Root Makefile) ---
TARGET_ARCH ?= $(error TARGET_ARCH is not set)
OUTPUT_DIR  ?= $(error OUTPUT_DIR is not set)
CACHE_DIR   ?= $(error CACHE_DIR is not set)
# CROSS_COMPILE is expected to be set in the environment by the root Makefile if needed

# --- Guest Specific Configuration ---
GUEST_NAME := linux-6.11
KERNEL_VERSION := 6.11
BUSYBOX_VERSION := 1.36.1

# --- Architecture Setup ---
KERNEL_ARCH := $(TARGET_ARCH)
export ARCH := $(KERNEL_ARCH)
# CROSS_COMPILE is passed via environment

# --- Paths ---
# Source Rootfs (relative to this Makefile)
SOURCE_ROOTFS_DIR := rootfs


# Cache paths
KERNEL_TARBALL := $(CACHE_DIR)/linux-$(KERNEL_VERSION).tar.xz
BUSYBOX_TARBALL := $(CACHE_DIR)/busybox-$(BUSYBOX_VERSION).tar.bz2

# Config Paths (relative to this Makefile)
# Using the filenames shown in 'ls config/'
FILESYSTEMS_CONFIG := config/filesystems.config
ARCH_KERNEL_CONFIG := config/kernel.$(KERNEL_ARCH).config
# Using kernel.config as an optional base override after defconfig (can be empty if not needed)
# This is primarily a dependency; the script itself might not need its path if it only merges the other two.
OPTIONAL_BASE_CONFIG := config/kernel.config
# BusyBox config still uses the ensure_link logic for simplicity
DEFAULT_BUSYBOX_CONFIG := config/busybox.config
BUSYBOX_CONFIG_FILE := config/busybox.$(KERNEL_ARCH).config

# Script paths (relative to this Makefile)
SCRIPT_DIR := scripts
BUILD_KERNEL_SH := $(SCRIPT_DIR)/build_kernel.sh
BUILD_ROOTFS_SH := $(SCRIPT_DIR)/build_rootfs.sh
BUILD_9P_SH := $(SCRIPT_DIR)/build_9p.sh
BUILD_BUSYBOX_SH := $(SCRIPT_DIR)/build_busybox.sh
BUILD_INITRAMFS_SH := $(SCRIPT_DIR)/build_initramfs.sh
ENSURE_LINK_SH := $(SCRIPT_DIR)/ensure_link.sh
COPY_KERNEL_SH := $(SCRIPT_DIR)/copy_kernel_image.sh

# Final Output Paths (within OUTPUT_DIR provided by root Makefile)
FINAL_KERNEL_NAME := kernel # Name of the kernel file within OUTPUT_DIR
FINAL_KERNEL := $(OUTPUT_DIR)/$(FINAL_KERNEL_NAME)
FINAL_INITRAMFS := $(OUTPUT_DIR)/initramfs.cpio.gz
FINAL_RUN_SH := $(OUTPUT_DIR)/run.sh
FINAL_META_CONF := $(OUTPUT_DIR)/meta.conf

# --- Intermediate Build Locations / Stamps ---
BUSYBOX_INSTALL_DIR := $(CACHE_DIR)/$(GUEST_NAME)-busybox-$(TARGET_ARCH)-install
BUSYBOX_INSTALL_STAMP := $(BUSYBOX_INSTALL_DIR)/.stamp
KERNEL_BUILD_DIR := $(CACHE_DIR)/$(GUEST_NAME)-kernel-$(TARGET_ARCH)-build
KERNEL_BUILD_STAMP := $(KERNEL_BUILD_DIR)/.kernel_built
STAGING_ROOTFS_DIR := $(CACHE_DIR)/rootfs-$(TARGET_ARCH)
ROOTFS_STAGING_STAMP := $(STAGING_ROOTFS_DIR)/.rootfs_prepared

# --- Targets ---
.PHONY: all image clean downloads

# Main target called by root Makefile
# Depends on the final artifacts
image: $(FINAL_KERNEL) $(FINAL_INITRAMFS) $(FINAL_RUN_SH) $(FINAL_META_CONF)

# --- Download Targets ---
downloads: $(KERNEL_TARBALL) $(BUSYBOX_TARBALL)

$(KERNEL_TARBALL):
	@echo "Ensuring cache directory $(CACHE_DIR) exists..."
	@mkdir -p "$(CACHE_DIR)"
	@echo "Downloading Kernel $(KERNEL_VERSION)..."
	wget -c "https://cdn.kernel.org/pub/linux/kernel/v$(shell echo $(KERNEL_VERSION) | cut -d. -f1).x/$(notdir $@)" -O "$@" || (rm -f "$@"; exit 1)

$(BUSYBOX_TARBALL):
	@echo "Ensuring cache directory $(CACHE_DIR) exists..."
	@mkdir -p "$(CACHE_DIR)"
	@echo "Downloading BusyBox $(BUSYBOX_VERSION)..."
	wget -c "https://busybox.net/downloads/$(notdir $@)" -O "$@" || (rm -f "$@"; exit 1)

# --- Kernel Build (Intermediate Stamp) ---
# Depends on the actual config files present:
# $(FILESYSTEMS_CONFIG) is the primary config fragment.
# $(ARCH_KERNEL_CONFIG) is the architecture-specific fragment.
# $(OPTIONAL_BASE_CONFIG) is also listed as a dependency, but might not be explicitly passed if the script doesn't use it.
$(KERNEL_BUILD_STAMP): $(KERNEL_TARBALL) $(FILESYSTEMS_CONFIG) $(ARCH_KERNEL_CONFIG) $(OPTIONAL_BASE_CONFIG) $(BUILD_KERNEL_SH)
	@echo "Building Kernel via script for KERNEL_ARCH=$(KERNEL_ARCH) into $(KERNEL_BUILD_DIR)..."
	# Assuming build_kernel.sh expects 7 arguments:
	# KERNEL_VERSION, KERNEL_ARCH, PRIMARY_CONFIG, ARCH_CONFIG, CACHE_DIR, KERNEL_BUILD_DIR, CROSS_COMPILE
	# We pass FILESYSTEMS_CONFIG as PRIMARY and ARCH_KERNEL_CONFIG as ARCH specific.
	$(BUILD_KERNEL_SH) \
		"$(KERNEL_VERSION)" \
		"$(KERNEL_ARCH)" \
		"$(FILESYSTEMS_CONFIG)" \
		"$(ARCH_KERNEL_CONFIG)" \
		"$(CACHE_DIR)" \
		"$(KERNEL_BUILD_DIR)" \
		"$(CROSS_COMPILE)" \
	&& touch $@
	@if [ $$? -ne 0 ]; then echo "Kernel build script failed!"; exit 1; fi


# --- Kernel Copy (Final Output) ---
# Depends on the intermediate kernel build stamp and the copy script
$(FINAL_KERNEL): $(KERNEL_BUILD_STAMP) $(COPY_KERNEL_SH)
	@echo "Copying final kernel image using script..."
	@mkdir -p "$(OUTPUT_DIR)" # Ensure final output dir exists
	$(COPY_KERNEL_SH) \
		"$(KERNEL_BUILD_DIR)" \
		"$(KERNEL_ARCH)" \
		"$@"
	@if [ $$? -ne 0 ]; then echo "Kernel copy script failed!"; exit 1; fi


# --- BusyBox Config Handling ---
# Ensures the arch-specific busybox config file exists (as file or link).
$(BUSYBOX_CONFIG_FILE): $(DEFAULT_BUSYBOX_CONFIG) $(ENSURE_LINK_SH)
	@echo "Ensuring BusyBox config link/file exists for $@..."
	$(ENSURE_LINK_SH) "$@" "$(DEFAULT_BUSYBOX_CONFIG)"
	@if [ $$? -ne 0 ]; then echo "BusyBox config setup script failed!"; exit 1; fi

# --- BusyBox Build (Intermediate Stamp) ---
# Depends on the config file target. Script handles output dir creation.
$(BUSYBOX_INSTALL_STAMP): $(BUSYBOX_TARBALL) $(BUSYBOX_CONFIG_FILE) $(BUILD_BUSYBOX_SH)
	@echo "Building BusyBox via script using config $(BUSYBOX_CONFIG_FILE)..."
	$(BUILD_BUSYBOX_SH) \
		"$(BUSYBOX_VERSION)" \
		"$(KERNEL_ARCH)" \
		"$(BUSYBOX_CONFIG_FILE)" \
		"$(CACHE_DIR)" \
		"$(BUSYBOX_INSTALL_DIR)" \
		"$(CROSS_COMPILE)" \
	&& touch $@
	@if [ $$? -ne 0 ]; then echo "BusyBox build script failed!"; exit 1; fi

# --- Rootfs Staging (Intermediate Stamp) ---
# Depends on the source rootfs content (e.g., init script), busybox install,
# and the build scripts for rootfs and 9p.
# Note: build_rootfs.sh now internally handles 9pserve placement.
$(ROOTFS_STAGING_STAMP): $(SOURCE_ROOTFS_DIR)/init $(BUSYBOX_INSTALL_STAMP) $(BUILD_9P_SH) $(BUILD_ROOTFS_SH)
	@echo "Preparing staging rootfs directory $(STAGING_ROOTFS_DIR)..."
	# build_rootfs.sh no longer needs FINAL_9PSERVE path argument
	$(BUILD_ROOTFS_SH) \
		"$(TARGET_ARCH)" \
		"$(SOURCE_ROOTFS_DIR)" \
		"$(STAGING_ROOTFS_DIR)" \
		"$(CACHE_DIR)" \
		"$(BUILD_9P_SH)" \
	&& touch $@
	@if [ $$? -ne 0 ]; then echo "Rootfs staging script failed!"; exit 1; fi

# --- Initramfs Build (Final Output) --- UPDATED TARGET
# Depends on kernel build AND rootfs staging being complete
$(FINAL_INITRAMFS): $(KERNEL_BUILD_STAMP) $(ROOTFS_STAGING_STAMP) $(BUILD_INITRAMFS_SH)
	@echo "Building Initramfs via script..."
	@mkdir -p "$(OUTPUT_DIR)" # Ensure final output dir exists
	# Call the updated script with STAGING_ROOTFS_DIR
	# Pass full KERNEL_VERSION if needed by script, e.g., 6.11.0
	$(BUILD_INITRAMFS_SH) \
		"$(KERNEL_VERSION)" \
		"$(KERNEL_ARCH)" \
		"$(KERNEL_BUILD_DIR)" \
		"$(STAGING_ROOTFS_DIR)" \
		"$@"
	@if [ $$? -ne 0 ]; then echo "Initramfs build script failed!"; exit 1; fi

# --- run.sh Generation (Final Output) ---
# Depends on the template. Replaces placeholders using sed directly.
$(FINAL_RUN_SH): run.sh.template
	@echo "Generating $@ from template..."
	@mkdir -p "$(OUTPUT_DIR)" # Ensure final output dir exists
	$(eval QEMU_CMD := $(shell which qemu-system-$(KERNEL_ARCH) 2>/dev/null || echo qemu-system-$(KERNEL_ARCH)))
	sed -e 's|@@QEMU_COMMAND@@|$(QEMU_CMD)|g' \
		-e 's|@@KERNEL_FILENAME@@|$(FINAL_KERNEL_NAME)|g' \
		-e 's|@@INITRAMFS_FILENAME@@|initramfs.cpio.gz|g' \
		-e 's|@@TARGET_ARCH@@|$(TARGET_ARCH)|g' \
		-e 's|@@KERNEL_ARCH@@|$(KERNEL_ARCH)|g' \
		run.sh.template > $@
	@if [ $$? -ne 0 ]; then echo "Run script generation failed!"; rm -f $@; exit 1; fi
	chmod +x $@

# --- meta.conf Copy (Final Output) ---
# Depends on the source file.
$(FINAL_META_CONF): meta.conf
	@echo "Copying meta.conf to $@"
	@mkdir -p "$(OUTPUT_DIR)"
	cp meta.conf $@

# --- Clean Target ---
clean:
	@echo todo: remove cache dir for guest and build output dir

