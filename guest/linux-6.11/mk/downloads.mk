# mk/downloads.mk - Download source archives

KERNEL_TARBALL := $(CACHE_DIR)/linux-$(KERNEL_VERSION).tar.xz
BUSYBOX_TARBALL := $(CACHE_DIR)/busybox-$(BUSYBOX_VERSION).tar.bz2
DROPBEAR_VERSION ?= 2025.87
DROPBEAR_TARBALL := $(CACHE_DIR)/dropbear-$(DROPBEAR_VERSION).tar.bz2
DIOD_VERSION ?= 1.0.24
DIOD_TARBALL := $(CACHE_DIR)/diod-$(DIOD_VERSION).tar.gz

.PHONY: downloads
downloads: $(KERNEL_TARBALL) $(BUSYBOX_TARBALL) $(DROPBEAR_TARBALL) $(DIOD_TARBALL)

$(KERNEL_TARBALL):
	mkdir -p "$(CACHE_DIR)"
	wget -c "https://cdn.kernel.org/pub/linux/kernel/v6.x/$(notdir $@)" -O "$@"

$(BUSYBOX_TARBALL):
	mkdir -p "$(CACHE_DIR)"
	wget -c "https://busybox.net/downloads/$(notdir $@)" -O "$@"

$(DROPBEAR_TARBALL):
	mkdir -p "$(CACHE_DIR)"
	wget -c "https://matt.ucc.asn.au/dropbear/releases/$(notdir $@)" -O "$@"

$(DIOD_TARBALL):
	mkdir -p "$(CACHE_DIR)"
	wget -c "https://github.com/chaos/diod/releases/download/$(DIOD_VERSION)/$(notdir $@)" -O "$@"
