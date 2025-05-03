# guest/linux-6.11/Makefile
# Orchestrates guest image build by calling scripts.
# Focuses on dependencies between scripts via stamp files and final outputs.

# --- Input Variables (Expected from Root Makefile) ---
# TARGET_ARCH: The architecture to build for (e.g., x86_64, arm64)
TARGET_ARCH ?= $(error TARGET_ARCH is not set)
# OUTPUT_DIR: The final destination directory for this specific guest build
OUTPUT_DIR  ?= $(error OUTPUT_DIR is not set)
# CACHE_DIR: The shared cache directory for downloads and intermediate builds
CACHE_DIR   ?= $(error CACHE_DIR is not set)

# --- Guest Specific Configuration ---
GUEST_NAME := linux-6.11
# KERNEL_VERSION: Ensure this matches the actual kernel version used in downloads/builds
KERNEL_VERSION := 6.11
BUSYBOX_VERSION := 1.36.1

# --- Architecture Setup ---
# KERNEL_ARCH: The architecture name used by the Linux kernel build system
KERNEL_ARCH := $(TARGET_ARCH)
CROSS_COMPILE_PREFIX :=
ifeq ($(KERNEL_ARCH), arm64)
    CROSS_COMPILE_PREFIX := aarch64-linux-gnu-
endif
# Add other architectures and their cross-compile prefixes if needed
# Example: riscv64-linux-gnu-

# Export ARCH and CROSS_COMPILE for build scripts
export ARCH := $(KERNEL_ARCH)
export CROSS_COMPILE ?= $(CROSS_COMPILE_PREFIX)
# FINAL_KERNEL_NAME: Base name for the kernel file in the output directory
FINAL_KERNEL_NAME := kernel

# --- Paths ---
# Cache paths for downloaded tarballs
KERNEL_TARBALL := $(CACHE_DIR)/linux-$(KERNEL_VERSION).tar.xz
BUSYBOX_TARBALL := $(CACHE_DIR)/busybox-$(BUSYBOX_VERSION).tar.bz2

# Configuration file paths (relative to this Makefile)
DEFAULT_KERNEL_CONFIG := config/kernel.config
KERNEL_CONFIG_FILE := config/kernel.$(KERNEL_ARCH).config
FILESYSTEMS_CONFIG_FILE := config/filesystems.config
DEFAULT_BUSYBOX_CONFIG := config/busybox.config
BUSYBOX_CONFIG_FILE := config/busybox.$(KERNEL_ARCH).config

# Script paths (relative to this Makefile)
SCRIPT_DIR := scripts
BUILD_KERNEL_SH := $(SCRIPT_DIR)/build_kernel.sh
COPY_KERNEL_SH := $(SCRIPT_DIR)/copy_kernel_image.sh
BUILD_BUSYBOX_SH := $(SCRIPT_DIR)/build_busybox.sh
BUILD_INITRAMFS_SH := $(SCRIPT_DIR)/build_initramfs.sh
ENSURE_LINK_SH := $(SCRIPT_DIR)/ensure_link.sh
BUILD_9P_SH := $(SCRIPT_DIR)/build_9p.sh

# Final Output Paths (within the specific guest build output dir: OUTPUT_DIR)
FINAL_KERNEL := $(OUTPUT_DIR)/$(FINAL_KERNEL_NAME)
FINAL_INITRAMFS := $(OUTPUT_DIR)/initramfs.cpio.gz
FINAL_RUN_SH := $(OUTPUT_DIR)/run.sh
FINAL_META_CONF := $(OUTPUT_DIR)/meta.conf
# Define path for the final static 9pserve binary within the build output
FINAL_STATIC_9PSERVE := $(OUTPUT_DIR)/9pserve

# --- Intermediate Build Locations / Stamps ---
# These are typically within the CACHE_DIR for build artifacts
BUSYBOX_INSTALL_DIR := $(CACHE_DIR)/$(GUEST_NAME)-busybox-$(TARGET_ARCH)-install
KERNEL_BUILD_DIR := $(CACHE_DIR)/$(GUEST_NAME)-kernel-$(TARGET_ARCH)-build
# Stamp files indicate successful completion of intermediate steps
KERNEL_BUILD_STAMP := $(KERNEL_BUILD_DIR)/.kernel_built
BUSYBOX_INSTALL_STAMP := $(BUSYBOX_INSTALL_DIR)/.stamp
# Stamp file for the 9pserve build (using the final binary path as base)
STATIC_9PSERVE_STAMP := $(FINAL_STATIC_9PSERVE).stamp

# --- Targets ---
.PHONY: all image clean downloads

# Main target called by root Makefile
# Depends on final outputs and the 9pserve stamp file
image: $(FINAL_KERNEL) $(FINAL_INITRAMFS) $(FINAL_RUN_SH) $(FINAL_META_CONF) $(STATIC_9PSERVE_STAMP)

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

# --- Kernel Config Handling ---
# Ensures the arch-specific kernel config file exists (as file or link).
$(KERNEL_CONFIG_FILE): $(DEFAULT_KERNEL_CONFIG) $(ENSURE_LINK_SH)
	@echo "Ensuring Kernel config link/file exists for $@..."
	$(ENSURE_LINK_SH) "$@" "$(DEFAULT_KERNEL_CONFIG)"
	@if [ $$? -ne 0 ]; then echo "Kernel config setup script failed!"; exit 1; fi

# --- Kernel Build (Intermediate Stamp) ---
# Depends on the config file target. Script handles output dir creation.
$(KERNEL_BUILD_STAMP): $(KERNEL_TARBALL) $(KERNEL_CONFIG_FILE) $(FILESYSTEMS_CONFIG_FILE) $(BUILD_KERNEL_SH)
	@echo "Building Kernel via script for KERNEL_ARCH=$(KERNEL_ARCH) into $(KERNEL_BUILD_DIR)..."
	$(BUILD_KERNEL_SH) \
		"$(KERNEL_VERSION)" \
		"$(KERNEL_ARCH)" \
		"$(KERNEL_CONFIG_FILE)" \
		"$(FILESYSTEMS_CONFIG_FILE)" \
		"$(CACHE_DIR)" \
		"$(KERNEL_BUILD_DIR)" \
		"$(CROSS_COMPILE_PREFIX)" \
	&& touch $@
	@if [ $$? -ne 0 ]; then echo "Kernel build script failed!"; exit 1; fi

# --- Kernel Copy (Final Output) ---
# Depends on the intermediate stamp and the copy script. Script handles output dir creation.
$(FINAL_KERNEL): $(KERNEL_BUILD_STAMP) $(COPY_KERNEL_SH)
	@echo "Copying final kernel image using script..."
	# Ensure final output dir exists
	@mkdir -p "$(OUTPUT_DIR)"
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
		"$(CROSS_COMPILE_PREFIX)" \
	&& touch $@
	@if [ $$? -ne 0 ]; then echo "BusyBox build script failed!"; exit 1; fi

# --- Static 9pserve Build (Stamp) ---
# Depends on the build script itself
$(STATIC_9PSERVE_STAMP): $(BUILD_9P_SH)
	@echo "Building static 9pserve via script..."
	# Pass target arch, the final desired path, and the cache dir
	# Ensure CACHE_DIR is passed correctly (relative or absolute)
	$(BUILD_9P_SH) "$(TARGET_ARCH)" "$(FINAL_STATIC_9PSERVE)" "$(CACHE_DIR)"
	@if [ $$? -ne 0 ]; then echo "Static 9pserve build script failed!"; exit 1; fi
	# Create stamp file on success
	@touch $@

# --- Initramfs Build (Final Output) ---
# Depends on intermediate stamps AND the 9pserve stamp.
$(FINAL_INITRAMFS): $(KERNEL_BUILD_STAMP) $(BUSYBOX_INSTALL_STAMP) $(STATIC_9PSERVE_STAMP) $(BUILD_INITRAMFS_SH) init.sh
	@echo "Building Initramfs via script..."
	# Ensure final output dir exists
	@mkdir -p "$(OUTPUT_DIR)"
	# Pass the path to the *final* static 9pserve binary as the last argument
	$(BUILD_INITRAMFS_SH) \
		"$(KERNEL_VERSION)" \
		"$(KERNEL_ARCH)" \
		"$(KERNEL_BUILD_DIR)" \
		"$(BUSYBOX_INSTALL_DIR)" \
		"init.sh" \
		"$@" \
		"$(CROSS_COMPILE_PREFIX)" \
		"$(FINAL_STATIC_9PSERVE)" # Pass the path to the built binary
	@if [ $$? -ne 0 ]; then echo "Initramfs build script failed!"; exit 1; fi

# --- run.sh Generation (Final Output) ---
# Depends on the template. Replaces placeholders using sed directly.
$(FINAL_RUN_SH): run.sh.template
	@echo "Generating $@ from template..."
	# Ensure final output dir exists
	@mkdir -p "$(OUTPUT_DIR)"
	# Determine the QEMU command path dynamically
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
	# Ensure final output dir exists
	@mkdir -p "$(OUTPUT_DIR)"
	cp meta.conf $@

# --- Clean Target ---
# Note: Cleaning OUTPUT_DIR and CACHE_DIR/build should ideally be handled by the root Makefile
# This clean target only removes guest-specific generated files not covered elsewhere.
clean:
	@echo "Guest clean target: Removing 9pserve binary and stamp."
	rm -f "$(FINAL_STATIC_9PSERVE)" "$(STATIC_9PSERVE_STAMP)"
	# Intermediate build directories (KERNEL_BUILD_DIR, BUSYBOX_INSTALL_DIR)
	# and the final OUTPUT_DIR are better cleaned by the root Makefile
	# to avoid accidentally deleting shared cache items or other guest builds.

