---
os: netbsd
support:
  # filesystems
  - format/fs/ext2
  - format/fs/fat12
  - format/fs/fat16
  - format/fs/fat32
  - format/fs/iso9660
  - format/fs/highsierra
  - format/fs/ufs1
  - format/fs/ufs2
  - format/fs/lfs
  - format/fs/efs
  - format/fs/amiga-ffs
  - format/fs/amiga-ofs
  - format/fs/filecore
  # partition tables
  - format/pt/mbr
  - format/pt/gpt
  - format/pt/bsd-disklabel
  - format/pt/apm
  - format/pt/amiga-rdb
  - format/pt/atari
  # transports
  - transport/9p
  - transport/sh
---

# NetBSD 10.0 Guest

NetBSD guest for qemount, providing filesystem mounting capabilities via QEMU.

## Kernel-Only Support (needs dynamic libraries for mount)

These filesystems have kernel support but mount helpers require dynamic
libraries which aren't available in the static rescue environment:

| Filesystem | Description | Notes |
|------------|-------------|-------|
| HFS/HFS+ | Apple Hierarchical Filesystem | Read-only |
| UDF | Universal Disk Format | DVD/Blu-ray |
| V7FS | 7th Edition Unix Filesystem | Historical |
| NFS | Network File System | Would need networking |

## Architecture

- Boot disk with embedded ramdisk (md0)
- Kernel: GENERIC + QEMOUNT customizations
- Root filesystem: FFS v1 on memory disk
- Console: Serial (com0)

## Future Work

- 9P mode for FUSE integration
- Dynamic library support for HFS, UDF, V7FS mount helpers
- Additional architecture support (aarch64)
