# mk/downloads.mk - Download targets

# Download paths
KERNEL_TARBALL := $(CACHE_DIR)/linux-$(KERNEL_VERSION).tar.xz
BUSYBOX_TARBALL := $(CACHE_DIR)/busybox-$(BUSYBOX_VERSION).tar.bz2

.PHONY: downloads
downloads: $(KERNEL_TARBALL) $(BUSYBOX_TARBALL)

$(KERNEL_TARBALL):
	mkdir -p "$(CACHE_DIR)"
	wget -c "https://cdn.kernel.org/pub/linux/kernel/v$(shell echo $(KERNEL_VERSION) | cut -d. -f1).x/$(notdir $@)" -O "$@"

$(BUSYBOX_TARBALL):
	mkdir -p "$(CACHE_DIR)"
	wget -c "https://busybox.net/downloads/$(notdir $@)" -O "$@"