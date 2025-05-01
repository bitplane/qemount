# TODO: Implementation Steps

This file lists steps required to complete and flesh out the rootless microVM PoC.

## ✅ Completed
- Kernel configuration with module support (e.g. `isofs.ko`)
- Initramfs creation using BusyBox with minimal applets
- Copying `init` script from shared overlay
- ISO9660 image generation (`build-iso.sh`)
- QEMU run script with version-aware paths and error handling
- Basic Makefile targets: `build-kernel`, `build-initramfs`, `build-iso`, `run`
- Version-aware kernel path handling in Makefile and `run-qemu.sh`
- Canonical initramfs output path fixed (`build/initramfs/initramfs.cpio.gz`)
- All build paths now controlled via Makefile; scripts accept variables as arguments or env
- All build scripts (kernel, initramfs, ISO, run) are now Makefile-driven and path-correct

## 🐛 Bugs
- **`init`** can't be found (file not found error) even when using /bin/ls

## 🔜 Next Steps
- **`init` script variants**: Add support for per-filesystem `init` overrides (e.g. `overlays/ext4/init`, etc.)
- **QEMU serial interaction**: Add kernel logging to serial and optional shell prompt (`exec sh`) fallback
- **Test script**: Add a quick test target to `Makefile` that boots QEMU, checks for `/mnt/hello.txt`, and exits
- **Dropbear integration (optional)**: Include small SSH server for VM access (forward port 2222)
- **Support virtio-9p (optional)**: Mount a host directory via 9p for read/write filesystem testing
- **Cross-arch support**: Generalize paths/configs for aarch64 and add ARCH-aware config selection
- **Packaging and cleanup**:
  - Add `make clean` steps for ISO, initramfs, and kernel artifacts
  - Create a `make dist` or `make image` target to bundle artifacts for sharing
- **Makefile optimization**:
  - Use artifact paths (`$(KERNEL_IMAGE)`, etc.) as targets
  - Remove `run` phony rebuilds unless needed

## 💡 Exploratory Ideas
- Add overlay hooks per filesystem type (e.g. preload modules, preload data)
- Rootless socket mount helpers (e.g. launch per-mount microVMs via Unix socket triggers)
- Automate detection of host filesystems and inject drivers dynamically
- Shell wrapper or CLI frontend (e.g. `afuse99p mount.iso`) that launches a microVM transparently
