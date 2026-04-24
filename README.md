# 🔌 qemount

Let's mount everything/anything using qemu, by exposing it over 9p. Spin up a
tiny VM that provides access to an image, one instance per mount.

## ✅ STATUS

⚠️  unstable / pre-alpha / experimental ⚠️

## 🛑 STOP! 🛑

MAKE BACKUPS OF YOUR DISK IMAGES BEFORE USING THIS TOOL.

Currently, there's:

* Linux 2.6, Linux 6.12 and NetBSD 10.0 guests
* 9P2000.U support in both a simple9p server and 9pfuse client
* Scripts to start the FUSE client
* A collection of filesystems to play with
* A build system that isolates everything inside containers, so it actually
  builds easily.
* A way to archive everything, inputs, outputs and containers, so the
  archive.org dumps will work long after the sources go offline.

To use it:

1. Install `podman`, `fuse`, `make` and `qemu`. `pigz` if you're archiving
2. Type `make` to build the guests.
3. Use `./build/run-qemu.sh` to start one of the guests with `-i some-image`
   and `-m 9p` to run the 9p init script. (BSD needs manual execution at
   present; run ./init.9p from the shell)
4. Once it's started and is grumbling about not having a connection (not
   before), connect to it with the 9p FUSE client using:
   `build/clients/linux-fuse/x86_64/bin/9pfuse /tmp/9p.sock /some/mount/point`

If the stars align, you'll have full access to the files in your given disk
image.

## Format support

### Partition tables

| Partition Table  | Linux 6.12 | Linux 2.6 | NetBSD 10 | Notes                          |
| ---------------- | ---------- | --------- | --------- | ------------------------------ |
| **MBR/DOS**      | ✅         | ✅        | ✅        | Classic PC, up to 4 primary    |
| **GPT**          | ✅         | ✅        | ✅        | Modern standard, >2TB          |
| **BSD disklabel**| ✅         | ✅        | ✅        | Native BSD partitioning        |
| **Apple APM**    | ✅         | ✅        | ✅        | Classic Mac partition map      |
| **Amiga RDB**    | ✅         | ✅        | ✅        | Rigid Disk Block               |
| **Atari AHDI**   | ✅         | ✅        | ✅        | Atari ST/TOS                   |
| **Sun VTOC**     | ✅         | ✅        | ❌        | Solaris/SunOS                  |
| **SGI DVH**      | ✅         | ✅        | ❌        | IRIX disks                     |
| **LDM**          | ✅         | ❌        | ❌        | Windows dynamic disks          |
| **Minix**        | ✅         | ✅        | ❌        | Minix subpartitions            |
| **UBI**          | ✅         | ✅        | ❌        | NAND flash volumes (not a PT)  |
| **Acorn**        | ✅         | ✅        | ❌        | RISC OS partition map          |
| **AIX**          | ✅         | ✅        | ❌        | IBM AIX PV headers             |
| **Ultrix**       | ✅         | ✅        | ❌        | DEC Ultrix (VAX/MIPS)          |
| **SYSV68**       | ✅         | ✅        | ❌        | Motorola 68k System V          |
| **IBM DASD**     | ❌         | ❌        | ❌        | S/390 mainframe                |
| **PC-98**        | ❌         | ❌        | ❌        | NEC PC-98 (Japan)              |
| **Rio Karma**    | ✅         | ❌        | ❌        | Portable media player          |
| **OSF/1**        | ✅         | ✅        | ❌        | DEC Alpha / Tru64              |
| **HP-UX LIF**    | ✅         | ✅        | ❌        | PA-RISC / Itanium              |
| **QNX4 PT**      | ✅         | ✅        | ❌        | QNX subpartitions              |
| **Plan 9**       | ✅         | ✅        | ❌        | ASCII partition table          |
| **NetWare**      | ✅         | ✅        | ❌        | Novell                         |
| **Hybrid MBR**   | ✅         | ✅        | ✅        | GPT+MBR dual boot              |
| **Protective MBR**| ✅        | ✅        | ✅        | GPT guard                      |
| **OpenBSD**      | ✅         | ✅        | ❌        | 16-partition disklabel         |
| **DragonFly**    | ✅         | ❌        | ❌        | Disklabel64 variant            |
| **NeXT**         | ❌         | ❌        | ❌        | NeXTSTEP / OPENSTEP            |
| **CP/M-86**      | ✅         | ✅        | ❌        | Digital Research               |

## Filesystems

| Filesystem       | Linux 6.12 | Linux 2.6 | NetBSD 10 | Notes                            |
| ---------------- | ---------- | --------- | --------- | -------------------------------- |
| **ext2**         | ✅         | ✅        | ✅        |                                  |
| **ext3**         | ✅         | ✅        | ✅        | NetBSD mounts as ext2            |
| **ext4**         | ✅         | ✅        | ❌        |                                  |
| **FAT12/16/32**  | ✅         | ✅        | ✅        | vfat/msdos                       |
| **exFAT**        | ✅         | ❌        | ❌        |                                  |
| **NTFS**         | ✅ ntfs3   | 💩 ntfs   | 💩 ntfs   | 6.12 has full r/w                |
| **ISO9660**      | ✅         | ✅        | ✅        | cd9660 on BSD                    |
| **UDF**          | ✅         | ✅        | ✅        | DVD/Blu-ray                      |
| **HFS**          | ✅         | ✅        | ✅        | Classic Mac                      |
| **HFS+**         | ✅         | ✅        | ❌        | hfsplus                          |
| **UFS/FFS**      | 💩         | 💩        | ✅        | Linux UFS is limited             |
| **LFS**          | ❌         | ❌        | ✅        | NetBSD log-structured            |
| **XFS**          | ✅         | ✅        | ❌        |                                  |
| **JFS**          | ✅         | ✅        | ❌        | IBM journaled                    |
| **Btrfs**        | ✅         | ✅        | ❌        |                                  |
| **F2FS**         | ✅         | ❌        | ❌        | Flash-friendly                   |
| **bcachefs**     | ✅         | ❌        | ❌        |                                  |
| **EROFS**        | ✅         | ❌        | ❌        | Read-only compressed             |
| **ReiserFS**     | ✅         | ✅        | ❌        | Removed in 6.13                  |
| **AFFS**         | ✅         | ✅        | 💩 adosfs | Amiga OFS/FFS                    |
| **SFS**          | ❌         | ❌        | ❌        | Amiga Smart FS (needs AROS)      |
| **PFS**          | ❌         | ❌        | ❌        | Amiga Professional FS (needs AROS)|
| **Minix**        | ✅         | ✅        | ❌        |                                  |
| **V7**           | ✅         | ✅        | ✅        | 7th Edition UNIX                 |
| **SysV**         | ✅         | 💩        | ❌        | System V - symlinks crash 2.6    |
| **SquashFS**     | ✅         | ✅        | ❌        | Read-only compressed             |
| **CramFS**       | ✅         | ✅        | ❌        | Read-only compressed             |
| **RomFS**        | ✅         | ✅        | ❌        | Read-only                        |
| **EFS**          | ✅         | ✅        | ✅        | SGI IRIX                         |
| **BeFS**         | ✅         | ✅        | ❌        | BeOS/Haiku                       |
| **HPFS**         | ✅         | ✅        | ❌        | OS/2                             |
| **QNX4**         | ✅         | ✅        | ❌        |                                  |
| **QNX6**         | ✅         | ❌        | ❌        |                                  |
| **ADFS**         | ✅         | ✅        | ❌        | Acorn                            |
| **Filecore**     | ❌         | ❌        | ✅        | Acorn RISC OS                    |
| **VxFS**         | ✅         | ✅        | ❌        | Veritas                          |
| **OMFS**         | ✅         | ✅        | ❌        | Optimized MPEG FS                |
| **NILFS2**       | ✅         | ✅        | ❌        | Log-structured                   |
| **GFS2**         | ✅         | ✅        | ❌        | Red Hat cluster                  |
| **OCFS2**        | ❌         | ✅        | ❌        | Oracle cluster                   |
| **Coda**         | ❌         | ❌        | ✅        | Distributed FS                   |
| **BFS**          | ✅         | ✅        | ❌        | SCO Boot FS                      |
| **ZFS**          | ❌         | ❌        | ✅        | OpenZFS (module, not in-kernel)  |
| **APFS**         | ❌         | ❌        | ❌        | Apple macOS 10.13+               |
| **ReFS**         | ❌         | ❌        | ❌        | Windows Resilient FS             |
| **HAMMER2**      | ❌         | ❌        | ❌        | DragonFly BSD native             |
| **JFFS2**        | ✅         | ✅        | ❌        | Flash journaling                 |
| **UBIFS**        | ✅         | ❌        | ❌        | UBI Flash FS                     |
| **High Sierra**  | ✅         | ✅        | ✅        | ISO9660 extension (Apple)        |
