# 🔌 qemount

Mount anything by giving the image to an operating system that understands it,
then exposing the result over 9P. qemount runs one small guest per image, using
real kernels and filesystem implementations instead of reimplementing every
format on the host.

## ✅ STATUS

⚠️  unstable / pre-alpha / experimental ⚠️

## 🛑 STOP! 🛑

MAKE BACKUPS OF YOUR DISK IMAGES BEFORE USING THIS TOOL.

Currently, there's:

* Linux 2.6, Linux 6.12, NetBSD 10.0, AROS and Haiku guests (currently x86 only)
* 9P2000.U support via a simple9p server and 9pfuse client.
* A huge collection of test data fixtures, with many custom mkfs and archive and
  compression tools.
* A Python-based podman-isolated build system that runs rootless and dodges
  dependency hell.
* A Rust library to detect and extract filesystems from many image formats.
* Full archival: sources, outputs and containers used to build everything,
  saved on archive.org for future historians. 

### Building

Install: 

* `podman`, `make`, `python3` + venv + pip to build.
* `fuse` to mount images with the 9p client.
* `xz` if you want to archive the lot.

Everything else is installed in containers, use the `qemount_build` module or
script to build stuff. It might take a while.

```sh
# install
make dev
source .venv/bin/activate

# list targets
qemount_build outputs

# pick one and build it
qemount_build build bin/qemu/x86_64-linux/6.12/boot/rootfs.img

make help  # for a full list of targets.
# make     # or just build the world!
```

Guest and transport selection, the detection engine and launch layer are still
under construction, see the [todo list](src/qemount_build/docs/todo.md). There's
`./scripts` for data recovery though.

Catalogue and format encyclopedia can be found is in the `src/qemount_build/`
tree - there's no html builder yet.

## Format support

Guest operating systems are the smallest thing I could get running with broadest
support. This is what works so far; YMMV.

### Partition tables

| Partition Table    | Linux 6.12 | Linux 2.6 | NetBSD 10 | AROS i386 | Haiku x86_64 | Notes                           |
| ------------------ | ---------- | --------- | --------- | --------- | ------------ | ------------------------------- |
| **MBR/DOS**        | ✅         | ✅        | ✅        | ✅        | ✅           |                                 |
| **GPT**            | ✅         | ✅        | ✅        | ✅        | ✅           |                                 |
| **BSD disklabel**  | ✅         | ✅        | ✅        | ❌        | ❌           | Native BSD partitioning         |
| **Apple APM**      | ✅         | ✅        | ✅        | ❌        | ❌           | Classic Mac partition map       |
| **Amiga RDB**      | ✅         | ✅        | ✅        | ✅        | ❌           |                                 |
| **Atari AHDI**     | ✅         | ✅        | ✅        | ❌        | ❌           | Atari ST/TOS                    |
| **Sun VTOC**       | ✅         | ✅        | ❌        | ❌        | ❌           | Solaris/SunOS                   |
| **SGI DVH**        | ✅         | ✅        | ❌        | ❌        | ❌           | IRIX disks                      |
| **LDM**            | ✅         | ❌        | ❌        | ❌        | ❌           | Windows dynamic disks           |
| **Minix**          | ✅         | ✅        | ❌        | ❌        | ❌           | Minix subpartitions             |
| **UBI**            | ✅         | ✅        | ❌        | ❌        | ❌           | NAND flash volumes (not a PT)   |
| **Acorn**          | ✅         | ✅        | ❌        | ❌        | ❌           | RISC OS partition map           |
| **AIX**            | ✅         | ✅        | ❌        | ❌        | ❌           | IBM AIX PV headers              |
| **Ultrix**         | ✅         | ✅        | ❌        | ❌        | ❌           | DEC Ultrix (VAX/MIPS)           |
| **SYSV68**         | ✅         | ✅        | ❌        | ❌        | ❌           | Motorola 68k System V           |
| **IBM DASD**       | ❌         | ❌        | ❌        | ❌        | ❌           | S/390 mainframe                 |
| **PC-98**          | ❌         | ❌        | ❌        | ❌        | ❌           | NEC PC-98 (Japan)               |
| **Rio Karma**      | ✅         | ❌        | ❌        | ❌        | ❌           | Portable media player           |
| **OSF/1**          | ✅         | ✅        | ❌        | ❌        | ❌           | DEC Alpha / Tru64               |
| **HP-UX LIF**      | ✅         | ✅        | ❌        | ❌        | ❌           | PA-RISC / Itanium               |
| **QNX4 PT**        | ✅         | ✅        | ❌        | ❌        | ❌           | QNX subpartitions               |
| **Plan 9**         | ✅         | ✅        | ❌        | ❌        | ❌           | ASCII partition table           |
| **NetWare**        | ✅         | ✅        | ❌        | ❌        | ❌           | Novell                          |
| **Hybrid MBR**     | ✅         | ✅        | ✅        | ❌        | ✅           |                                 |
| **Protective MBR** | ✅         | ✅        | ✅        | ✅        | ✅           |                                 |
| **OpenBSD**        | ✅         | ✅        | ❌        | ❌        | ❌           | 16-partition disklabel          |
| **DragonFly**      | ✅         | ❌        | ❌        | ❌        | ❌           | Disklabel64 variant             |
| **NeXT**           | ❌         | ❌        | ❌        | ❌        | ❌           | NeXTSTEP / OPENSTEP             |
| **CP/M-86**        | ✅         | ✅        | ❌        | ❌        | ❌           | Digital Research                |

### Filesystems

| Filesystem      | Linux 6.12 | Linux 2.6 | NetBSD 10 | AROS      | Haiku x86_64 | Notes                             |
| --------------- | ---------- | --------- | --------- | --------- | ------------ | --------------------------------- |
| **ext2**        | ✅         | ✅        | ✅        | ❌        | ✅           |                                   |
| **ext3**        | ✅         | ✅        | ✅        | ❌        | ✅           | NetBSD mounts as ext2             |
| **ext4**        | ✅         | ✅        | ❌        | ❌        | ✅           |                                   |
| **FAT12**       | ✅         | ✅        | ✅        | ✅        | ✅           |                                   |
| **FAT16/32**    | ✅         | ✅        | ✅        | ✅        | ✅           |                                   |
| **exFAT**       | ✅         | ❌        | ❌        | ❌        | ✅ ro        |                                   |
| **NTFS**        | ✅ ntfs3   | 💩 ntfs   | 💩 ntfs   | ❌        | ✅           |                                   |
| **ISO9660**     | ✅         | ✅        | ✅        | ✅        | ✅           | Several variants tested           |
| **UDF**         | ✅         | ✅        | ✅        | ❌        | ✅ ro        | DVD/Blu-ray                       |
| **HFS**         | ✅         | ✅        | ✅        | ❌        | ❌           | Classic Mac                       |
| **HFS+**        | ✅         | ✅        | ❌        | ❌        | ❌           | hfsplus                           |
| **UFS/FFS**     | 💩         | 💩        | ✅        | ❌        | ❌           | Linux UFS is limited              |
| **LFS**         | ❌         | ❌        | ✅        | ❌        | ❌           | NetBSD log-structured             |
| **XFS**         | ✅         | ✅        | ❌        | ❌        | ❌           |                                   |
| **JFS**         | ✅         | ✅        | ❌        | ❌        | ❌           | IBM journaled                     |
| **Btrfs**       | ✅         | ✅        | ❌        | ❌        | ✅ ro        |                                   |
| **F2FS**        | ✅         | ❌        | ❌        | ❌        | ❌           | Flash-friendly                    |
| **bcachefs**    | ✅         | ❌        | ❌        | ❌        | ❌           |                                   |
| **EROFS**       | ✅         | ❌        | ❌        | ❌        | ❌           | Read-only compressed              |
| **ReiserFS**    | ✅         | ✅        | ❌        | ❌        | ✅ ro        | Removed in 6.13                   |
| **Amiga OFS**   | ✅         | ✅        | 💩 adosfs | ✅        | ❌           |                                   |
| **Amiga FFS**   | ✅         | ✅        | 💩 adosfs | ✅        | ❌           |                                   |
| **SFS**         | ❌         | ❌        | ❌        | ✅        | ❌           |                                   |
| **PFS**         | ❌         | ❌        | ❌        | ✅        | ❌           |                                   |
| **Minix**       | ✅         | ✅        | ❌        | ❌        | ❌           |                                   |
| **V7**          | ✅         | ✅        | ✅        | ❌        | ❌           | 7th Edition UNIX                  |
| **SysV**        | ✅         | 💩        | ❌        | ❌        | ❌           | System V; symlinks crash 2.6      |
| **SquashFS**    | ✅         | ✅        | ❌        | ❌        | ❌           | Read-only compressed              |
| **CramFS**      | ✅         | ✅        | ❌        | ❌        | ❌           | Read-only compressed              |
| **RomFS**       | ✅         | ✅        | ❌        | ❌        | ❌           | Read-only                         |
| **EFS**         | ✅         | ✅        | ✅        | ❌        | ❌           | SGI IRIX                          |
| **BeFS**        | ✅         | ✅        | ❌        | ❌        | ✅           | BeOS/Haiku                        |
| **HPFS**        | ✅         | ✅        | ❌        | ❌        | ❌           | OS/2                              |
| **QNX4**        | ✅         | ✅        | ❌        | ❌        | ❌           |                                   |
| **QNX6**        | ✅         | ❌        | ❌        | ❌        | ❌           |                                   |
| **ADFS**        | ✅         | ✅        | ❌        | ❌        | ❌           | Acorn                             |
| **Filecore**    | ❌         | ❌        | ✅        | ❌        | ❌           | Acorn RISC OS                     |
| **VxFS**        | ✅         | ✅        | ❌        | ❌        | ❌           | Veritas                           |
| **OMFS**        | ✅         | ✅        | ❌        | ❌        | ❌           | Optimized MPEG FS                 |
| **NILFS2**      | ✅         | ✅        | ❌        | ❌        | ❌           | Log-structured                    |
| **GFS2**        | ✅         | ✅        | ❌        | ❌        | ❌           | Red Hat cluster                   |
| **OCFS2**       | ❌         | ✅        | ❌        | ❌        | ❌           | Oracle cluster                    |
| **Coda**        | ❌         | ❌        | ✅        | ❌        | ❌           | Distributed FS                    |
| **BFS**         | ✅         | ✅        | ❌        | ❌        | ❌           | SCO Boot FS                       |
| **ZFS**         | ❌         | ❌        | ✅        | ❌        | ❌           | OpenZFS (module, not in-kernel)   |
| **APFS**        | ❌         | ❌        | ❌        | ❌        | ❌           | Apple macOS 10.13+                |
| **ReFS**        | ❌         | ❌        | ❌        | ❌        | ❌           | Windows Resilient FS              |
| **HAMMER2**     | ❌         | ❌        | ❌        | ❌        | ❌           | DragonFly BSD native              |
| **JFFS2**       | ✅         | ✅        | ❌        | ❌        | ❌           | Flash journaling                  |
| **UBIFS**       | ✅         | ❌        | ❌        | ❌        | ❌           | UBI Flash FS                      |
| **High Sierra** | ✅         | ✅        | ✅        | ❌        | ❌           | ISO9660 predecessor               |
