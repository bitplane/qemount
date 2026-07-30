# 🔌 qemount

Mount anything by giving the image to an operating system that understands it,
then exposing the result over 9P. qemount runs one small guest per image, using
real kernels and filesystem implementations instead of reimplementing every
format on the host.

## ✅ STATUS

⚠️  unstable / pre-alpha / experimental ⚠️

## 🛑 STOP! 🛑

MAKE BACKUPS OF YOUR DISK IMAGES BEFORE USING THIS TOOL.

Currently, there are:

* Linux 2.6, Linux 6.12, NetBSD 10.0 and AROS i386 guests
* 9P2000.U support in both a simple9p server and 9pfuse client
* Platform filesystem discovery: `/` on POSIX guests and a synthetic root
  containing mounted DOS volumes on AROS
* A roughly 3 MiB allowlisted AROS guest for Amiga OFS, FFS, SFS and PFS volumes
* A collection of filesystems to play with
* A build system that isolates everything inside containers, so it actually
  builds easily
* A way to archive everything, inputs, outputs and containers, so the
  archive.org dumps will work long after the sources go offline

### Building

Install `podman`, `fuse`, `make` and `qemu`; install `xz` too if you want to
create archival builds. The catalogue exposes individual build targets:

```sh
python -m qemount_build outputs
python -m qemount_build build bin/qemu/x86_64-linux/6.12/boot/rootfs.img
python -m qemount_build build bin/qemu/x86_64-netbsd/10.0/boot/boot.img
python -m qemount_build build bin/qemu/i386-aros/boot/aros.iso
python -m qemount_build build bin/x86_64-linux-musl/9pfuse
```

`make archive` performs a separate clean build inside a privileged outer
container, then exports that complete environment as a compressed time capsule.
It includes the source history, downloaded inputs, outputs, logs, caches, and
the nested Podman image store containing all builder toolchains.

The guest-selection and launch layer is still under construction, see the
[todo list](src/qemount_build/docs/todo.md).

## Format support

This is what works so far, sometimes with a bit of connect script tweaking.

### Partition tables

| Partition Table   | Linux 6.12 | Linux 2.6 | NetBSD 10 | AROS i386 | Notes                         |
| ----------------- | ---------- | --------- | --------- | --------- | ----------------------------- |
| **MBR/DOS**       | ✅         | ✅        | ✅        | ✅        |                               |
| **GPT**           | ✅         | ✅        | ✅        | ✅        |                               |
| **BSD disklabel** | ✅         | ✅        | ✅        | ❌        | Native BSD partitioning       |
| **Apple APM**     | ✅         | ✅        | ✅        | ❌        | Classic Mac partition map     |
| **Amiga RDB**     | ✅         | ✅        | ✅        | ✅        |                               |
| **Atari AHDI**    | ✅         | ✅        | ✅        | ❌        | Atari ST/TOS                  |
| **Sun VTOC**      | ✅         | ✅        | ❌        | ❌        | Solaris/SunOS                 |
| **SGI DVH**       | ✅         | ✅        | ❌        | ❌        | IRIX disks                    |
| **LDM**           | ✅         | ❌        | ❌        | ❌        | Windows dynamic disks         |
| **Minix**         | ✅         | ✅        | ❌        | ❌        | Minix subpartitions           |
| **UBI**           | ✅         | ✅        | ❌        | ❌        | NAND flash volumes (not a PT) |
| **Acorn**         | ✅         | ✅        | ❌        | ❌        | RISC OS partition map         |
| **AIX**           | ✅         | ✅        | ❌        | ❌        | IBM AIX PV headers            |
| **Ultrix**        | ✅         | ✅        | ❌        | ❌        | DEC Ultrix (VAX/MIPS)         |
| **SYSV68**        | ✅         | ✅        | ❌        | ❌        | Motorola 68k System V         |
| **IBM DASD**      | ❌         | ❌        | ❌        | ❌        | S/390 mainframe               |
| **PC-98**         | ❌         | ❌        | ❌        | ❌        | NEC PC-98 (Japan)             |
| **Rio Karma**     | ✅         | ❌        | ❌        | ❌        | Portable media player         |
| **OSF/1**         | ✅         | ✅        | ❌        | ❌        | DEC Alpha / Tru64             |
| **HP-UX LIF**     | ✅         | ✅        | ❌        | ❌        | PA-RISC / Itanium             |
| **QNX4 PT**       | ✅         | ✅        | ❌        | ❌        | QNX subpartitions             |
| **Plan 9**        | ✅         | ✅        | ❌        | ❌        | ASCII partition table         |
| **NetWare**       | ✅         | ✅        | ❌        | ❌        | Novell                        |
| **Hybrid MBR**    | ✅         | ✅        | ✅        | ❌        | Partitions are not auto-mounted |
| **Protective MBR**| ✅         | ✅        | ✅        | ✅        |                               |
| **OpenBSD**       | ✅         | ✅        | ❌        | ❌        | 16-partition disklabel        |
| **DragonFly**     | ✅         | ❌        | ❌        | ❌        | Disklabel64 variant           |
| **NeXT**          | ❌         | ❌        | ❌        | ❌        | NeXTSTEP / OPENSTEP           |
| **CP/M-86**       | ✅         | ✅        | ❌        | ❌        | Digital Research              |

### Filesystems

| Filesystem      | Linux 6.12 | Linux 2.6 | NetBSD 10 | AROS      | Notes                             |
| --------------- | ---------- | --------- | --------- | --------- | --------------------------------- |
| **ext2**        | ✅         | ✅        | ✅        | ❌        |                                   |
| **ext3**        | ✅         | ✅        | ✅        | ❌        | NetBSD mounts as ext2             |
| **ext4**        | ✅         | ✅        | ❌        | ❌        |                                   |
| **FAT12**       | ✅         | ✅        | ✅        | ✅        |                                   |
| **FAT16/32**    | ✅         | ✅        | ✅        | ✅        |                                   |
| **exFAT**       | ✅         | ❌        | ❌        | ❌        |                                   |
| **NTFS**        | ✅ ntfs3   | 💩 ntfs   | 💩 ntfs   | ❌        |                                   |
| **ISO9660**     | ✅         | ✅        | ✅        | ✅        | Several variants tested           |
| **UDF**         | ✅         | ✅        | ✅        | ❌        | DVD/Blu-ray                       |
| **HFS**         | ✅         | ✅        | ✅        | ❌        | Classic Mac                       |
| **HFS+**        | ✅         | ✅        | ❌        | ❌        | hfsplus                           |
| **UFS/FFS**     | 💩         | 💩        | ✅        | ❌        | Linux UFS is limited              |
| **LFS**         | ❌         | ❌        | ✅        | ❌        | NetBSD log-structured             |
| **XFS**         | ✅         | ✅        | ❌        | ❌        |                                   |
| **JFS**         | ✅         | ✅        | ❌        | ❌        | IBM journaled                     |
| **Btrfs**       | ✅         | ✅        | ❌        | ❌        |                                   |
| **F2FS**        | ✅         | ❌        | ❌        | ❌        | Flash-friendly                    |
| **bcachefs**    | ✅         | ❌        | ❌        | ❌        |                                   |
| **EROFS**       | ✅         | ❌        | ❌        | ❌        | Read-only compressed              |
| **ReiserFS**    | ✅         | ✅        | ❌        | ❌        | Removed in 6.13                   |
| **Amiga OFS**   | ✅         | ✅        | 💩 adosfs | ✅        |                                   |
| **Amiga FFS**   | ✅         | ✅        | 💩 adosfs | ✅        |                                   |
| **SFS**         | ❌         | ❌        | ❌        | ✅        |                                   |
| **PFS**         | ❌         | ❌        | ❌        | ✅        |                                   |
| **Minix**       | ✅         | ✅        | ❌        | ❌        |                                   |
| **V7**          | ✅         | ✅        | ✅        | ❌        | 7th Edition UNIX                  |
| **SysV**        | ✅         | 💩        | ❌        | ❌        | System V; symlinks crash 2.6      |
| **SquashFS**    | ✅         | ✅        | ❌        | ❌        | Read-only compressed              |
| **CramFS**      | ✅         | ✅        | ❌        | ❌        | Read-only compressed              |
| **RomFS**       | ✅         | ✅        | ❌        | ❌        | Read-only                         |
| **EFS**         | ✅         | ✅        | ✅        | ❌        | SGI IRIX                          |
| **BeFS**        | ✅         | ✅        | ❌        | ❌        | BeOS/Haiku                        |
| **HPFS**        | ✅         | ✅        | ❌        | ❌        | OS/2                              |
| **QNX4**        | ✅         | ✅        | ❌        | ❌        |                                   |
| **QNX6**        | ✅         | ❌        | ❌        | ❌        |                                   |
| **ADFS**        | ✅         | ✅        | ❌        | ❌        | Acorn                             |
| **Filecore**    | ❌         | ❌        | ✅        | ❌        | Acorn RISC OS                     |
| **VxFS**        | ✅         | ✅        | ❌        | ❌        | Veritas                           |
| **OMFS**        | ✅         | ✅        | ❌        | ❌        | Optimized MPEG FS                 |
| **NILFS2**      | ✅         | ✅        | ❌        | ❌        | Log-structured                    |
| **GFS2**        | ✅         | ✅        | ❌        | ❌        | Red Hat cluster                   |
| **OCFS2**       | ❌         | ✅        | ❌        | ❌        | Oracle cluster                    |
| **Coda**        | ❌         | ❌        | ✅        | ❌        | Distributed FS                    |
| **BFS**         | ✅         | ✅        | ❌        | ❌        | SCO Boot FS                       |
| **ZFS**         | ❌         | ❌        | ✅        | ❌        | OpenZFS (module, not in-kernel)   |
| **APFS**        | ❌         | ❌        | ❌        | ❌        | Apple macOS 10.13+                |
| **ReFS**        | ❌         | ❌        | ❌        | ❌        | Windows Resilient FS              |
| **HAMMER2**     | ❌         | ❌        | ❌        | ❌        | DragonFly BSD native              |
| **JFFS2**       | ✅         | ✅        | ❌        | ❌        | Flash journaling                  |
| **UBIFS**       | ✅         | ❌        | ❌        | ❌        | UBI Flash FS                      |
| **High Sierra** | ✅         | ✅        | ✅        | ❌        | ISO9660 predecessor               |
