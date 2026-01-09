---
title: System V
created: 1983
related:
  - fs/v7
  - fs/sco-bfs
  - fs/minix
detect:
  - offset: 0x3f8
    type: le32
    value: 0xfd187e20
---

# System V Filesystem (sysv)

The System V filesystem was used by AT&T Unix System V and its derivatives
including SCO Unix, Xenix, and Coherent. It evolved from the V7 filesystem
with improvements for larger disks and better performance.

## Characteristics

- 512 or 1024 byte blocks
- 14 character filename limit (inherited from V7)
- 16-bit inode numbers
- Free block list (not bitmap)
- Superblock at block 1
- 24-bit block addresses (3 bytes per pointer)

## Structure

- Boot block at block 0
- Superblock at block 1 (offset 512)
- Magic 0xFD187E20 at offset 504 within superblock (0x3F8 total)
- Inode table starts at block 2
- Data blocks follow

## Variants

The Linux kernel sysv driver supports multiple variants:

| Type | Description |
|------|-------------|
| Xenix | Microsoft/SCO Xenix |
| SystemV/386 | AT&T System V for x86 |
| Coherent | Mark Williams Coherent Unix |

## Known Issues

- Symlink creation crashes Linux 2.6.39 (NULL pointer in sysv_symlink)
- Removed from Linux 6.x kernels
- Limited tooling available (no modern mkfs.sysv)

## Current Status

- **Removed** from mainline Linux (6.x)
- Accessible via Linux 2.6 kernels
- qemount includes custom mkfs.sysv for creating images
- Useful for accessing legacy SCO/Xenix systems

## Historical Note

This is one of the few filesystems where we had to write our own mkfs tool
from scratch, as the original was removed from util-linux years ago.
