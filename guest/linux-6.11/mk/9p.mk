# mk/9p.mk - Build diod (9p server)

9P_VERSION ?= 1.0.24
DIOD_TARBALL := $(CACHE_DIR)/diod-$(9P_VERSION).tar.gz
DIOD_STAMP := $(STAGING_ROOTFS_DIR)/bin/diod

.PHONY: diod
diod: $(DIOD_STAMP)

$(DIOD_STAMP): $(ROOTFS_STAGING_STAMP) $(DIOD_TARBALL)
	$(SCRIPT_DIR)/build_9p.sh \
		"$(9P_VERSION)" \
		"$(TARGET_ARCH)" \
		"$(CACHE_DIR)" \
		"$(DIOD_STAMP)" \
		"$(CROSS_COMPILE)"
