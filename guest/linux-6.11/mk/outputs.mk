# mk/outputs.mk - Final output generation

# Generate run script
$(FINAL_RUN_SH): run.sh.template
	mkdir -p "$(OUTPUT_DIR)"
	$(eval QEMU_CMD := $(shell which qemu-system-$(KERNEL_ARCH) 2>/dev/null || echo qemu-system-$(KERNEL_ARCH)))
	sed -e 's|@@QEMU_COMMAND@@|$(QEMU_CMD)|g' \
		-e 's|@@KERNEL_FILENAME@@|$(FINAL_KERNEL_NAME)|g' \
		-e 's|@@INITRAMFS_FILENAME@@|initramfs.cpio.gz|g' \
		-e 's|@@TARGET_ARCH@@|$(TARGET_ARCH)|g' \
		-e 's|@@KERNEL_ARCH@@|$(KERNEL_ARCH)|g' \
		run.sh.template > $@
	chmod +x $@

# Copy metadata
$(FINAL_META_CONF): meta.conf
	mkdir -p "$(OUTPUT_DIR)"
	cp meta.conf $@