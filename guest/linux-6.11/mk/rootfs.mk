ROOTFS_DIR := $(OUTPUT_DIR)/rootfs
ROOTFS_STAGING_STAMP := $(ROOTFS_DIR)/.staging-complete
SSH_DEPLOY_STAMP := $(ROOTFS_DIR)/.ssh-deploy-complete
STAGING_ROOTFS_DIR := $(ROOTFS_DIR)/staging
DROBEAR_BINARY := $(CACHE_DIR)/dropbearmulti-$(DROPBEAR_VERSION)-$(TARGET_ARCH)

# Rebuild if any overlay file changed
ROOTFS_OVERLAY_FILES := $(shell find rootfs -type f -print)

.PHONY: rootfs
rootfs: $(ROOTFS_STAGING_STAMP) $(SSH_DEPLOY_STAMP)

$(ROOTFS_STAGING_STAMP): $(BUSYBOX_BINARY) $(ROOTFS_OVERLAY_FILES)
	rm -rf "$(STAGING_ROOTFS_DIR)"
	mkdir -p "$(STAGING_ROOTFS_DIR)/bin"
	cp "$(BUSYBOX_BINARY)" "$(STAGING_ROOTFS_DIR)/bin/busybox"
	"$(STAGING_ROOTFS_DIR)/bin/busybox" --install -s "$(STAGING_ROOTFS_DIR)/bin"
	touch "$@"

$(SSH_DEPLOY_STAMP): $(ROOTFS_STAGING_STAMP) $(DROBEAR_BINARY)
	cp "$(DROBEAR_BINARY)" "$(STAGING_ROOTFS_DIR)/bin/dropbearmulti"
	ln -sf /bin/dropbearmulti "$(STAGING_ROOTFS_DIR)/bin/dropbear"
	touch "$@"
