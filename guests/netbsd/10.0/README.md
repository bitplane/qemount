# NetBSD 10.0 Guest

NetBSD guest for qemount, providing filesystem mounting capabilities via QEMU.

## Supported Filesystems

These filesystems are fully supported with kernel drivers and mount helpers:

| Filesystem | Mount Command | Description |
|------------|---------------|-------------|
| FFS/UFS1/UFS2 | mount_ffs | BSD Fast File System |
| EXT2/EXT3/EXT4 | mount_ext2fs | Linux Extended Filesystem |
| FAT12/FAT16/FAT32 | mount_msdos | MS-DOS/Windows FAT |
| ISO 9660 | mount_cd9660 | CD-ROM filesystem (+ Rock Ridge) |
| NTFS | mount_ntfs | Windows NT Filesystem (experimental) |
| LFS | mount_lfs | Log-structured Filesystem |
| EFS | mount_efs | Silicon Graphics Extent FS |
| ADOSFS | mount_ados | AmigaDOS Filesystem |
| FILECORE | mount_filecore | Acorn RISC OS Filesystem |

## Kernel-Only Support (needs dynamic libraries for mount)

These filesystems have kernel support but mount helpers require dynamic
libraries which aren't available in the static rescue environment:

| Filesystem | Description | Notes |
|------------|-------------|-------|
| HFS/HFS+ | Apple Hierarchical Filesystem | Read-only |
| UDF | Universal Disk Format | DVD/Blu-ray |
| V7FS | 7th Edition Unix Filesystem | Historical |
| NFS | Network File System | Would need networking |

## Pseudo-filesystems (internal use)

| Filesystem | Mount Command | Description |
|------------|---------------|-------------|
| tmpfs | mount_tmpfs | Memory-based filesystem |
| mfs | mount_mfs | Memory filesystem (BSD style) |
| kernfs | mount_kernfs | Kernel info (/kern) |
| procfs | mount_procfs | Process info (/proc) |
| ptyfs | mount_ptyfs | PTY devices |
| nullfs | mount_null | Loopback/null mount |
| overlay | mount_overlay | Overlay filesystem |
| union | mount_union | Union filesystem |

## Architecture

- Boot disk with embedded ramdisk (md0)
- Kernel: GENERIC + QEMOUNT customizations
- Root filesystem: FFS v1 on memory disk
- Console: Serial (com0)

## Usage

```bash
# Shell mode with disk image
./build/run-netbsd.sh x86_64 build/guests/netbsd/10.0/x86_64/boot.img -i <image> -m sh

# Without disk image (for testing)
./build/run-netbsd.sh x86_64 build/guests/netbsd/10.0/x86_64/boot.img -m sh
```

## Building

```bash
make guests/netbsd/10.0/x86_64/boot.img
```

## Future Work

- 9P mode for FUSE integration
- Dynamic library support for HFS, UDF, V7FS mount helpers
- Stripped kernel for faster boot
- Additional architecture support (aarch64)
