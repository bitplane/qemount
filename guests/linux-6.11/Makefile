# Essential variables
ARCH  ?= x86_64
OUT   := $(CURDIR)/../../build/guests/linux-6.11-$(ARCH)
CACHE := $(CURDIR)/../../build/cache/guests/linux-6.11/$(ARCH)

build := "podman build --build-arg ARCH=$(ARCH)"
run   := "podman run --rm -v $(OUT):/dest -v $(CACHE):/cache"

# Make sure directories exist
$(shell mkdir -p $(OUT) $(CACHE)/rootfs/bin)

# Default target builds all components
.PHONY: all
all: kernel initramfs meta


#
# 🧠 Build the kernel
#
.PHONY: kernel
kernel: $(OUT)/kernel
$(OUT)/kernel: $(wildcard kernel/*)
	cd kernel && podman build    \
		--build-arg ARCH=$(ARCH) \
		-t qemount-linux-kernel:$(ARCH) .
	mkdir -p $(OUT)
	podman run --rm -v $(OUT):/output qemount-linux-kernel:$(ARCH) \
		bash -c "cp /build/linux-*/arch/$(ARCH)/boot/bzImage /output/kernel"


#
# 💲 Build BusyBox
#
.PHONY: busybox
busybox: $(CACHE)/rootfs/bin/busybox
$(CACHE)/rootfs/bin/busybox: $(wildcard busybox/*)
	cd busybox && podman build \
		--build-arg ARCH=$(ARCH) \
		-t qemount-linux-busybox:$(ARCH) .
	mkdir -p $(CACHE)/rootfs/bin
	podman run --rm -v $(CACHE)/rootfs/bin:/output qemount-linux-busybox:$(ARCH) \
		bash -c "cp /build/busybox-*/busybox /output/"


#
# 🔌 Build SSH daemon
#
.PHONY: sshd
sshd: $(CACHE)/rootfs/bin/dropbearmulti
$(CACHE)/rootfs/bin/dropbearmulti: $(wildcard sshd/*)
	cd sshd && podman build \
		--build-arg ARCH=$(ARCH) \
		-t qemount-linux-sshd:$(ARCH) .
	mkdir -p $(CACHE)/rootfs/bin
	podman run --rm \
		-v $(CACHE)/rootfs/bin:/output qemount-linux-sshd:$(ARCH) \
		bash -c "cp /build/dropbear-*/dropbearmulti /output/"


#
# 🔌 Build 9P server
#
.PHONY: 9p
9p: $(CACHE)/rootfs/bin/diod
$(CACHE)/rootfs/bin/diod: $(wildcard 9p/*)
	cd 9p && podman build \
		--build-arg ARCH=$(ARCH) \
		-t qemount-linux-9p:$(ARCH) .
	mkdir -p $(CACHE)/rootfs/bin
	podman run --rm -v $(CACHE)/rootfs/bin:/output qemount-linux-9p:$(ARCH) \
		bash -c "cp /build/diod-*/src/diod /output/" 


#
# 📦 Build initramfs
#
.PHONY: initramfs
initramfs: $(OUT)/initramfs.cpio.gz
$(OUT)/initramfs.cpio.gz: busybox sshd $(wildcard initramrd/*)
	# Build initramfs.
	cd initramfs && podman build \
		-f initramfs/Dockerfile \
		--build-arg ARCH=$(ARCH) \
		-t qemount-linux-initramfs:$(ARCH) \
		-v $(CURDIR)/initramfs/root:/source
	mkdir -p $(OUT)
	podman run --rm \
		-v $(OUT):/output \
		qemount-linux-initramfs:$(ARCH) \
		bash -c "cp /build/initramfs.cpio.gz /output/"


#
# 📃 Generate catalogue
#
.PHONY: meta
meta: $(OUT)/meta.conf
$(OUT)/meta.conf: meta.conf
	mkdir -p $(OUT)
	cp $< $@


#
# 🧹 Clean build artifacts
#
.PHONY: clean
clean:
	rm -f $(OUT)/kernel $(OUT)/initramfs.cpio.gz $(OUT)/meta.conf
	rm -rf $(CACHE)/rootfs/bin
	podman rmi -f qemount-linux-kernel:$(ARCH)    || true
	podman rmi -f qemount-linux-busybox:$(ARCH)   || true
	podman rmi -f qemount-linux-sshd:$(ARCH)      || true
	podman rmi -f qemount-linux-9p:$(ARCH)        || true
	podman rmi -f qemount-linux-initramfs:$(ARCH) || true

# Deep clean 
.PHONY: distclean
distclean: clean
	podman system prune -f
