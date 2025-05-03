# guest/linux-6.11/Makefile
# Orchestrates guest image build using layered config and staging rootfs.

# --- Input Variables (Expected from Root Makefile) ---
TARGET_ARCH ?= $(error TARGET_ARCH is not set)
OUTPUT_DIR  ?= $(error OUTPUT_DIR is not set)
CACHE_DIR   ?= $(error CACHE_DIR is not set)
# CROSS_COMPILE is expected to be set in the environment by the root Makefile if needed

# --- Guest Specific Configuration ---
GUEST_NAME := linux-6.11
# Ensure KERNEL_VERSION includes patch level if scripts rely on it (e.g., 6.11.0)
KERNEL_VERSION := 6.11
BUSYBOX_VERSION := 1.36.1

# --- Architecture Setup ---
KERNEL_ARCH := $(TARGET_ARCH)
export ARCH := $(KERNEL_ARCH)
# CROSS_COMPILE is passed via environment

# --- Paths ---
# Ensure base paths are absolute
ABS_CACHE_DIR := $(abspath $(CACHE_DIR))
ABS_OUTPUT_DIR := $(abspath $(OUTPUT_DIR))

# Source Rootfs (relative to this Makefile's location)
SOURCE_ROOTFS_DIR := rootfs

# Cache paths (based on absolute cache dir)
KERNEL_TARBALL := $(ABS_CACHE_DIR)/linux-$(KERNEL_VERSION).tar.xz
BUSYBOX_TARBALL := $(ABS_CACHE_DIR)/busybox-$(BUSYBOX_VERSION).tar.bz2

# Config Paths (relative to this Makefile's location)
FILESYSTEMS_CONFIG := config/filesystems.config
ARCH_KERNEL_CONFIG := config/kernel.$(KERNEL_ARCH).config
OPTIONAL_BASE_CONFIG := config/kernel.config
DEFAULT_BUSYBOX_CONFIG := config/busybox.config
BUSYBOX_CONFIG_FILE := config/busybox.$(KERNEL_ARCH).config

# Script paths (relative to this Makefile's location)
SCRIPT_DIR := scripts
BUILD_KERNEL_SH := $(SCRIPT_DIR)/build_kernel.sh
BUILD_ROOTFS_SH := $(SCRIPT_DIR)/build_rootfs.sh
BUILD_9P_SH := $(SCRIPT_DIR)/build_9p.sh
BUILD_BUSYBOX_SH := $(SCRIPT_DIR)/build_busybox.sh
BUILD_INITRAMFS_SH := $(SCRIPT_DIR)/build_initramfs.sh
ENSURE_LINK_SH := $(SCRIPT_DIR)/ensure_link.sh
COPY_KERNEL_SH := $(SCRIPT_DIR)/copy_kernel_image.sh

# Final Output Paths (using absolute output dir)
FINAL_KERNEL_NAME := kernel
FINAL_KERNEL := $(ABS_OUTPUT_DIR)/$(FINAL_KERNEL_NAME)
FINAL_INITRAMFS := $(ABS_OUTPUT_DIR)/initramfs.cpio.gz
FINAL_RUN_SH := $(ABS_OUTPUT_DIR)/run.sh
FINAL_META_CONF := $(ABS_OUTPUT_DIR)/meta.conf

# --- Intermediate Build Locations / Stamps (using absolute cache dir) ---
BUSYBOX_INSTALL_DIR := $(ABS_CACHE_DIR)/$(GUEST_NAME)-busybox-$(TARGET_ARCH)-install
BUSYBOX_INSTALL_STAMP := $(BUSYBOX_INSTALL_DIR)/.stamp
KERNEL_BUILD_DIR := $(ABS_CACHE_DIR)/$(GUEST_NAME)-kernel-$(TARGET_ARCH)-build
KERNEL_BUILD_STAMP := $(KERNEL_BUILD_DIR)/.kernel_built
STAGING_ROOTFS_DIR := $(ABS_CACHE_DIR)/$(GUEST_NAME)-rootfs-$(TARGET_ARCH)-staging
ROOTFS_STAGING_STAMP := $(STAGING_ROOTFS_DIR)/.rootfs_prepared

# --- Targets ---
.PHONY: all image clean downloads

# Main target called by root Makefile
image: $(FINAL_KERNEL) $(FINAL_INITRAMFS) $(FINAL_RUN_SH) $(FINAL_META_CONF)

# --- Download Targets ---
downloads: $(KERNEL_TARBALL) $(BUSYBOX_TARBALL)

$(KERNEL_TARBALL):
	@echo "Ensuring cache directory $(ABS_CACHE_DIR) exists..."
	@mkdir -p "$(ABS_CACHE_DIR)"
	@echo "Downloading Kernel $(KERNEL_VERSION)..."
	wget -c "https://cdn.kernel.org/pub/linux/kernel/v$(shell echo $(KERNEL_VERSION) | cut -d. -f1).x/$(notdir $@)" -O "$@" || (rm -f "$@"; exit 1)

$(BUSYBOX_TARBALL):
	@echo "Ensuring cache directory $(ABS_CACHE_DIR) exists..."
	@mkdir -p "$(ABS_CACHE_DIR)"
	@echo "Downloading BusyBox $(BUSYBOX_VERSION)..."
	wget -c "https://busybox.net/downloads/$(notdir $@)" -O "$@" || (rm -f "$@"; exit 1)

# --- Kernel Build (Intermediate Stamp) ---
# Use absolute paths for directories passed to script
$(KERNEL_BUILD_STAMP): $(KERNEL_TARBALL) $(FILESYSTEMS_CONFIG) $(ARCH_KERNEL_CONFIG) $(OPTIONAL_BASE_CONFIG) $(BUILD_KERNEL_SH)
	@echo "Building Kernel via script for KERNEL_ARCH=$(KERNEL_ARCH) into $(KERNEL_BUILD_DIR)..."
	$(BUILD_KERNEL_SH) \
		"$(KERNEL_VERSION)" \
		"$(KERNEL_ARCH)" \
		"$(abspath $(FILESYSTEMS_CONFIG))" \
		"$(abspath $(ARCH_KERNEL_CONFIG))" \
		"$(ABS_CACHE_DIR)" \
		"$(KERNEL_BUILD_DIR)" \
		"$(CROSS_COMPILE)" \
	&& touch "$(KERNEL_BUILD_STAMP)"
	@if [ $$? -ne 0 ]; then echo "Kernel build script failed!"; exit 1; fi


# --- Kernel Copy (Final Output) ---
$(FINAL_KERNEL): $(KERNEL_BUILD_STAMP) $(COPY_KERNEL_SH)
	@echo "Copying final kernel image using script..."
	@mkdir -p "$(ABS_OUTPUT_DIR)"
	$(COPY_KERNEL_SH) \
		"$(KERNEL_BUILD_DIR)" \
		"$(KERNEL_ARCH)" \
		"$@"
	@if [ $$? -ne 0 ]; then echo "Kernel copy script failed!"; exit 1; fi


# --- BusyBox Config Handling ---
$(BUSYBOX_CONFIG_FILE): $(DEFAULT_BUSYBOX_CONFIG) $(ENSURE_LINK_SH)
	@echo "Ensuring BusyBox config link/file exists for $@..."
	$(ENSURE_LINK_SH) "$@" "$(DEFAULT_BUSYBOX_CONFIG)"
	@if [ $$? -ne 0 ]; then echo "BusyBox config setup script failed!"; exit 1; fi

# --- BusyBox Build (Intermediate Stamp) ---
$(BUSYBOX_INSTALL_STAMP): $(BUSYBOX_TARBALL) $(BUSYBOX_CONFIG_FILE) $(BUILD_BUSYBOX_SH)
	@echo "Building BusyBox via script using config $(BUSYBOX_CONFIG_FILE)..."
	$(BUILD_BUSYBOX_SH) \
		"$(BUSYBOX_VERSION)" \
		"$(KERNEL_ARCH)" \
		"$(abspath $(BUSYBOX_CONFIG_FILE))" \
		"$(ABS_CACHE_DIR)" \
		"$(BUSYBOX_INSTALL_DIR)" \
		"$(CROSS_COMPILE)" \
	&& touch "$(BUSYBOX_INSTALL_STAMP)"
	@if [ $$? -ne 0 ]; then echo "BusyBox build script failed!"; exit 1; fi

# --- Rootfs Staging (Intermediate Stamp) ---
# Depends on source rootfs (relative path ok here), busybox stamp, and scripts
$(ROOTFS_STAGING_STAMP): $(SOURCE_ROOTFS_DIR)/init $(BUSYBOX_INSTALL_STAMP) $(BUILD_9P_SH) $(BUILD_ROOTFS_SH)
	# *** REMOVED @ symbol from the next line for debugging ***
	echo "Preparing staging rootfs directory $(STAGING_ROOTFS_DIR)..."
	# Pass absolute paths to the script for directories it needs to access/create
	$(BUILD_ROOTFS_SH) \
		"$(TARGET_ARCH)" \
		"$(abspath $(SOURCE_ROOTFS_DIR))" \
		"$(STAGING_ROOTFS_DIR)" \
		"$(ABS_CACHE_DIR)" \
		"$(BUSYBOX_INSTALL_DIR)" \
	&& mkdir -p "$(STAGING_ROOTFS_DIR)" && touch "$(ROOTFS_STAGING_STAMP)" # Ensure dir exists before touch
	# Add error check after the command chain
	@if [ $$? -ne 0 ]; then echo "Rootfs staging script failed!"; exit 1; fi


# --- Initramfs Build (Final Output) ---
# Depends on kernel build AND rootfs staging being complete
$(FINAL_INITRAMFS): $(KERNEL_BUILD_STAMP) $(ROOTFS_STAGING_STAMP) $(BUILD_INITRAMFS_SH)
	@echo "Building Initramfs via script..."
	@mkdir -p "$(ABS_OUTPUT_DIR)"
	# Pass absolute paths to the script
	$(BUILD_INITRAMFS_SH) \
		"$(KERNEL_VERSION)" \
		"$(KERNEL_ARCH)" \
		"$(KERNEL_BUILD_DIR)" \
		"$(STAGING_ROOTFS_DIR)" \
		"$@"
	@if [ $$? -ne 0 ]; then echo "Initramfs build script failed!"; exit 1; fi

# --- run.sh Generation (Final Output) ---
$(FINAL_RUN_SH): run.sh.template
	@echo "Generating $@ from template..."
	@mkdir -p "$(ABS_OUTPUT_DIR)"
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
$(FINAL_META_CONF): meta.conf
	@echo "Copying meta.conf to $@"
	@mkdir -p "$(ABS_OUTPUT_DIR)"
	cp meta.conf $@

# --- Clean Target ---
# Note: Cleaning OUTPUT_DIR and CACHE_DIR/build should be handled by the root Makefile
clean:
	@echo "Guest clean target: Removing staging dir..."
	rm -rf "$(STAGING_ROOTFS_DIR)"
	# Optionally clean busybox install cache if not shared
	# rm -rf "$(BUSYBOX_INSTALL_DIR)"
	# Optionally clean kernel build dir
	# rm -rf "$(KERNEL_BUILD_DIR)"
	@echo "(Root Makefile should clean main build/output and cache dirs)."

