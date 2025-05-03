# mk/busybox.mk - BusyBox build

# BusyBox Config
BUSYBOX_DEFAULT_CONFIG := $(KERNEL_BUILD_DIR)/.busybox.defconfig
BUSYBOX_CONFIG := $(KERNEL_BUILD_DIR)/.busybox.config
BUSYBOX_BASE_CONFIG := config/busybox.config
BUSYBOX_ARCH_CONFIG := config/busybox.$(KERNEL_ARCH).config
BUSYBOX_INSTALL_STAMP := $(BUSYBOX_INSTALL_DIR)/.stamp
BUILD_BUSYBOX_SH := $(SCRIPT_DIR)/build_busybox.sh
MERGE_CONFIG_PY := $(SCRIPT_DIR)/merge_config.py

BUSYBOX_BINARY := $(CACHE_DIR)/busybox-$(BUSYBOX_VERSION)-$(TARGET_ARCH)

# Get default BusyBox config
$(BUSYBOX_DEFAULT_CONFIG): $(BUSYBOX_TARBALL)
	@echo "Getting BusyBox default config..."
	mkdir -p "$(BUSYBOX_SRC_DIR)" "$(dir $@)"
	if [ ! -d "$(BUSYBOX_SRC_DIR)/configs" ]; then \
		tar -xf "$(BUSYBOX_TARBALL)" --strip-components=1 -C "$(BUSYBOX_SRC_DIR)"; \
	fi
	cd "$(BUSYBOX_SRC_DIR)" && make allnoconfig >/dev/null 2>&1
	cp "$(BUSYBOX_SRC_DIR)/.config" "$@"

# Apply configuration layers
$(BUSYBOX_CONFIG): $(BUSYBOX_DEFAULT_CONFIG) $(BUSYBOX_BASE_CONFIG) $(wildcard $(BUSYBOX_ARCH_CONFIG))
	@echo "Creating layered BusyBox config..."
	cp "$<" "$@"
	if [ -f "$(BUSYBOX_BASE_CONFIG)" ]; then \
		cat "$(BUSYBOX_BASE_CONFIG)" >> "$@"; \
	fi
	if [ -f "$(BUSYBOX_ARCH_CONFIG)" ]; then \
		cat "$(BUSYBOX_ARCH_CONFIG)" >> "$@"; \
	fi

# Build BusyBox
$(BUSYBOX_INSTALL_STAMP): $(BUSYBOX_CONFIG) $(BUILD_BUSYBOX_SH) $(MERGE_CONFIG_PY)
	@echo "Building BusyBox for $(KERNEL_ARCH)..."
	$(BUILD_BUSYBOX_SH) \
		"$(BUSYBOX_VERSION)" \
		"$(KERNEL_ARCH)" \
		"$(abspath $<)" \
		"$(CACHE_DIR)" \
		"$(BUSYBOX_INSTALL_DIR)" \
		"$(CROSS_COMPILE)" \
		"$(abspath $(MERGE_CONFIG_PY))" \
	&& touch $@

# Export a standalone busybox binary for staging
$(BUSYBOX_BINARY): $(BUSYBOX_INSTALL_STAMP)
	cp "$(BUSYBOX_INSTALL_DIR)/bin/busybox" "$@"
