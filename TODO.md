# TODO: Implementation Steps

This file lists steps required to complete and flesh out the rootless microVM PoC:

- **Kernel Configuration**: Add needed kernel options for filesystem and virtio. For example, enable `CONFIG_ISO9660_FS`, `CONFIG_NET_9P`, and virtio drivers (network, block) in the kernel config, or ensure these are built as modules.

- **Initramfs `init` Script**: Create an init script (e.g. `init` or `init.sh`) inside the initramfs that will run on boot. This should:
  - Mount special filesystems (`/proc`, `/sys`).
  - Insert necessary modules with `insmod` (e.g. iso9660.ko).
  - Mount the ISO9660 filesystem (typically on `/mnt` or similar).
  - Possibly start `dropbear` or another SSH server for access.
  - Switch to a shell or continue to a login prompt.

- **ISO Image Creation**: Build or generate the ISO9660 image (`build/fs/iso9660/rootfs.iso`) containing some test data or rootfs. This could use tools like `genisoimage`/`mkisofs` or scripts (e.g. using Buildroot or Alpine to create a minimal filesystem). The Makefile or scripts should have a target to build this image.

- **Dynamic Modules in initramfs**: Ensure that any module dependencies are handled. Since we load modules manually, we might need to include dependencies in the initramfs or use insmod in the correct order. Alternatively, include a minimal `modules.dep`.

- **Networking**: Verify that networking (virtio-net with usermode net) works as intended. Configure `dropbear` keys and enable port forwarding so that SSH (port 22 in guest) is accessible on host (port 2222).

- **Cross-Platform Support**: Extend to other architectures (e.g. `aarch64`) by parameterizing `ARCH` and adding configuration. For each arch, cross-compile the kernel or use appropriate toolchains.

- **Size and Performance Optimizations**: Optimize the initramfs size by removing unnecessary files. Optionally, use compression or multistage init to reduce footprint. Evaluate performance of reverse-SSHFS vs. virtio-9p and document trade-offs.

- **Cleanup and Packaging**: Implement cleanup targets (e.g. `make clean`) and possibly packaging of final artifacts (e.g. creating a bootable ISO with kernel+initrd). Document usage of the scripts and possible customization.

- **Testing**: Create automated tests or step-by-step instructions to verify that:
  - Kernel boots and loads initramfs correctly.
  - ISO9660 mounts and content is accessible in the guest.
  - SSH access (dropbear) works over the forwarded port.
  - Rootless (non-root) invocation of QEMU succeeds.

Use these TODO items to guide the final implementation of the system.
