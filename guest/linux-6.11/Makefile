# guest/linux-6.11/Makefile
# Orchestrates guest image build by calling scripts.
# Focuses on dependencies between scripts via stamp files and final outputs.

# --- Input Variables (Expected from Root Makefile) ---
TARGET_ARCH ?= $(error TARGET_ARCH is not set)
OUTPUT_DIR  ?= $(error OUTPUT_DIR is not set)
CACHE_DIR   ?= $(error CACHE_DIR is not set)

# --- Guest Specific Configuration ---
GUEST_NAME := linux-6.11
KERNEL_VERSION := 6.11
BUSYBOX_VERSION := 1.36.1

# --- Architecture Setup ---
KERNEL_ARCH := $(TARGET_ARCH)
CROSS_COMPILE_PREFIX :=
export ARCH := $(KERNEL_ARCH)
export CROSS_COMPILE ?= $(CROSS_COMPILE_PREFIX)
FINAL_KERNEL_NAME := kernel

# --- Paths ---
# Cache paths
KERNEL_TARBALL := $(CACHE_DIR)/linux-$(KERNEL_VERSION).tar.xz
BUSYBOX_TARBALL := $(CACHE_DIR)/busybox-$(BUSYBOX_VERSION).tar.bz2

# Config Paths
DEFAULT_KERNEL_CONFIG := config/kernel.config
KERNEL_CONFIG_FILE := config/kernel.$(KERNEL_ARCH).config
DEFAULT_BUSYBOX_CONFIG := config/busybox.config
BUSYBOX_CONFIG_FILE := config/busybox.$(KERNEL_ARCH).config

# Script paths
SCRIPT_DIR := scripts
BUILD_KERNEL_SH := $(SCRIPT_DIR)/build_kernel.sh
COPY_KERNEL_SH := $(SCRIPT_DIR)/copy_kernel_image.sh
BUILD_BUSYBOX_SH := $(SCRIPT_DIR)/build_busybox.sh
BUILD_INITRAMFS_SH := $(SCRIPT_DIR)/build_initramfs.sh
ENSURE_LINK_SH := $(SCRIPT_DIR)/ensure_link.sh
# BUILD_RUN_SCRIPT_SH is no longer needed

# Final Output Paths
FINAL_KERNEL := $(OUTPUT_DIR)/$(FINAL_KERNEL_NAME)
FINAL_INITRAMFS := $(OUTPUT_DIR)/initramfs.cpio.gz
FINAL_RUN_SH := $(OUTPUT_DIR)/run.sh
FINAL_META_CONF := $(OUTPUT_DIR)/meta.conf

# --- Intermediate Build Locations / Stamps ---
# These paths are passed to scripts, which should create them if needed.
BUSYBOX_INSTALL_DIR := $(CACHE_DIR)/$(GUEST_NAME)-busybox-$(TARGET_ARCH)-install
KERNEL_BUILD_DIR := $(CACHE_DIR)/$(GUEST_NAME)-kernel-$(TARGET_ARCH)-build
KERNEL_BUILD_STAMP := $(KERNEL_BUILD_DIR)/.kernel_built
BUSYBOX_INSTALL_STAMP := $(BUSYBOX_INSTALL_DIR)/.stamp

# --- Targets ---
.PHONY: all image clean downloads

# Main target called by root Makefile
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

# --- Kernel Config Handling ---
# Ensures the arch-specific kernel config file exists (as file or link).
$(KERNEL_CONFIG_FILE): $(DEFAULT_KERNEL_CONFIG) $(ENSURE_LINK_SH)
	@echo "Ensuring Kernel config link/file exists for $@..."
	$(ENSURE_LINK_SH) "$@" "$(DEFAULT_KERNEL_CONFIG)"
	@if [ $$? -ne 0 ]; then echo "Kernel config setup script failed!"; exit 1; fi

# --- Kernel Build (Intermediate Stamp) ---
# Depends on the config file target. Script handles output dir creation.
$(KERNEL_BUILD_STAMP): $(KERNEL_TARBALL) $(KERNEL_CONFIG_FILE) $(BUILD_KERNEL_SH)
	@echo "Building Kernel via script for KERNEL_ARCH=$(KERNEL_ARCH) into $(KERNEL_BUILD_DIR)..."
	$(BUILD_KERNEL_SH) \
		"$(KERNEL_VERSION)" \
		"$(KERNEL_ARCH)" \
		"$(KERNEL_CONFIG_FILE)" \
		"$(CACHE_DIR)" \
		"$(KERNEL_BUILD_DIR)" \
		"$(CROSS_COMPILE)" \
	&& touch $@
	@if [ $$? -ne 0 ]; then echo "Kernel build script failed!"; exit 1; fi

# --- Kernel Copy (Final Output) ---
# Depends on the intermediate stamp and the copy script. Script handles output dir creation.
$(FINAL_KERNEL): $(KERNEL_BUILD_STAMP) $(COPY_KERNEL_SH)
	@echo "Copying final kernel image using script..."
	@mkdir -p "$(OUTPUT_DIR)" # Ensure final output dir exists
	$(COPY_KERNEL_SH) \
		"$(KERNEL_BUILD_DIR)" \
		"$(KERNEL_ARCH)" \
		"$@"
	@if [ $$? -ne 0 ]; then echo "Kernel copy script failed!"; exit 1; fi

# --- BusyBox Config Handling ---
# Depends on the default config and the ensure script. Script handles output dir creation.
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

# --- Initramfs Build (Final Output) ---
# Depends on intermediate stamps and the init script template. Script handles output dir creation.
$(FINAL_INITRAMFS): $(KERNEL_BUILD_STAMP) $(BUSYBOX_INSTALL_STAMP) $(BUILD_INITRAMFS_SH) init.sh
	@echo "Building Initramfs via script..."
	@mkdir -p "$(OUTPUT_DIR)" # Ensure final output dir exists
	$(BUILD_INITRAMFS_SH) \
		"$(KERNEL_VERSION)" \
		"$(KERNEL_ARCH)" \
		"$(KERNEL_BUILD_DIR)" \
		"$(BUSYBOX_INSTALL_DIR)" \
		"init.sh" \
		"$@" \
		"$(CROSS_COMPILE)"
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
# Depends on the source file. Script handles output dir creation.
$(FINAL_META_CONF): meta.conf
	@echo "Copying meta.conf to $@"
	@mkdir -p "$(OUTPUT_DIR)" # Ensure final output dir exists
	cp meta.conf $@

# --- Clean Target ---
# Note: Cleaning OUTPUT_DIR and CACHE_DIR/build should be handled by the root Makefile
clean:
	@echo "Guest clean target does nothing (Root Makefile cleans build dirs)."

