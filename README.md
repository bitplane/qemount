# Rootless QEMU MicroVM (x86_64, ISO9660)

This project provides a structured proof-of-concept (PoC) for booting a **rootless microVM** using QEMU on x86_64, with filesystem images (starting with ISO9660) mounted in a safe, user-space manner. The architecture is designed so that a single kernel image can be used for multiple filesystems; additional filesystem drivers (ISO9660, etc.) are provided as kernel modules in the initramfs. The system runs entirely without requiring root or hardware virtualization (KVM), relying instead on QEMU's user-mode processes.

## Architecture

- The **kernel** is compiled from an official Linux source tarball (configurable via `KERNEL_VERSION`) and copied into `build/linux/...`.
- The **initramfs** is generated as a CPIO (gz-compressed) archive containing BusyBox and minimal tools (e.g. `insmod`, `mount`). Filesystem drivers (e.g. the ISO9660 module) are added to the initramfs so they can be loaded at boot time.
- On boot, QEMU runs in "rootless" mode using user-mode networking (no `sudo` needed). The ISO9660 filesystem image is attached via `-cdrom` (or virtio disk) and mounted by the kernel (with the ISO9660 driver) on the guest side.
- SSH/SFTP access can be achieved by running a small SSH server (e.g. dropbear) in the initramfs, listening on the virtual serial console or forwarded TCP ports. Tools like Lima use a "reverse-sshfs" approach, where the host initiates an SFTP connection to the guest without opening host ports.
- Virtual devices (virtio-net, virtio-blk, etc.) are used so that user permissions are sufficient to use QEMU without additional privileges. The root filesystem is `initramfs` plus the mounted ISO.

## Building

The project uses **Makefile** and helper scripts to automate builds:

- `make build-kernel`: fetches and builds the Linux kernel for the target architecture. The example default is x86_64 using `ARCH=x86_64`.
- `make build-initramfs`: builds BusyBox and an initramfs image, then copies necessary kernel modules (e.g. ISO9660) into it.
- The **build scripts** (`scripts/build-kernel.sh`, `scripts/build-initramfs.sh`) contain placeholders to download upstream sources (kernel and BusyBox) and compile them. They also set up directory structure for the initramfs.
- The **Makefile** is dependency-aware: for example, `build-initramfs` depends on having built the kernel first so that the modules are available.

### Dependencies and Tools

- The workflow uses common toolchains (GNU `make`, `gcc`, etc.). Cross-compilation can be enabled by setting environment variables (e.g. `CROSS_COMPILE`) or modifying the scripts.
- BusyBox provides `ash`, `insmod`, `lsmod`, etc. as lightweight replacements for core utilities.
- Dropbear or another small SSH server can be integrated into the initramfs if remote access is needed. The scripts can be extended to include Dropbear and host key configuration.

## Running the PoC

To run the example microVM:

1. **Build the kernel and initramfs**:
    ```bash
    make build-kernel
    make build-initramfs
    ```
   These commands populate `build/linux/.../bzImage` and `build/initramfs/initramfs.cpio.gz`.

2. **Prepare an ISO image**:
   An example ISO9660 filesystem (e.g. containing test files) should be placed at `build/fs/iso9660/rootfs.iso`. (In a full implementation, you might use `mkisofs` or Buildroot/Alpine tooling to generate this image.)

3. **Run QEMU**:
    ```bash
    make run
    ```
   This invokes `qemu-system-x86_64` with the built kernel, initramfs, and attaches the ISO image as a CD-ROM. The example command line uses user-mode networking and forwards port 2222 -> 22 inside the guest, so you can `ssh -p 2222 localhost` if a server is running in the initramfs.

The `scripts/run-qemu.sh` file provides a template. For example, it shows how to use `-cdrom`, `-netdev user`, and virtio-net.

## Files and Directories

- `Makefile`: orchestrates builds and QEMU invocation.
- `README.md`: this document (overview and instructions).
- `TODO.md`: list of further implementation tasks to make the PoC fully functional.
- `scripts/`: placeholder scripts
  - `build-kernel.sh`: downloads and compiles Linux.
  - `build-initramfs.sh`: sets up BusyBox and creates `initramfs.cpio.gz`.
  - `run-qemu.sh`: launches QEMU with the generated artifacts.
- `build/`: output directory for compiled kernel, initramfs, and filesystem images.

## Notes

- **Modular Kernel**: By loading filesystem drivers from the initramfs, we avoid the need for a complete `/lib/modules` tree on disk. The initramfs can contain only the specific `.ko` files needed (e.g. `isofs.ko`) and use `insmod` at runtime to load them.
- **SSHFS/9P Options**: While this PoC uses a simple user-mode network and SSH port forwarding, tools like Lima demonstrate that "reverse SSHFS" (host as SFTP server) or virtio-9p can be used instead for file sharing without exposing TCP ports on the host. This shows flexibility in rootless microVM file access.
- **Further Work**: The `TODO.md` outlines steps to flesh out the implementation, such as constructing the ISO filesystem, integrating an init script (possibly `init` or `init.sh`), and adding proper module loading logic.

Example QEMU invocation (from `run-qemu.sh` template):
```bash
qemu-system-x86_64 \
  -kernel build/linux/arch/x86/boot/bzImage \
  -initrd build/initramfs/initramfs.cpio.gz \
  -append "console=ttyS0 root=/dev/ram0" \
  -cdrom build/fs/iso9660/rootfs.iso \
  -device virtio-net,netdev=usernet \
  -netdev user,id=usernet,hostfwd=tcp::2222-:22 \
  -nographic
```
This boots the kernel, uses the initramfs, mounts the ISO, and forwards host port 2222 to guest port 22 for SSH.
