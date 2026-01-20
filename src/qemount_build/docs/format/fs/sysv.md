---
title: System V
created: 1983
related:
  - format/fs/v7
  - format/fs/sco-bfs
  - format/fs/minix
detect:
  any:
    # SystemV: magic at offset 0x3f8 (block 1 + 0x1f8)
    - offset: 0x3f8
      type: le32
      value: 0xfd187e20
    # Xenix: magic at offset 0x5f8 (block 1 + 1016)
    - offset: 0x5f8
      type: le32
      value: 0x2b5544
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

| Type | Description | MBR Type |
|------|-------------|----------|
| Xenix | Microsoft/SCO Xenix | 0x02, 0x03 |
| SystemV/386 | AT&T System V for x86 | 0x63 |
| Coherent | Mark Williams Coherent Unix | 0x09 |
| OPUS | Unisys Open Parallel Server (SVR4) | 0x0A |

### Coherent

Coherent was a Unix clone marketed by Mark Williams Company from 1980 to 1995.
It sold for $99 and approximately 40,000 copies were sold. Coherent partitions
must be primary.

Unlike SystemV and Xenix, Coherent has no magic number. The Linux kernel
detects it by checking for specific strings in the superblock:

- `s_fname` field: "noname" or "xxxxx "
- `s_fpack` field: "nopack" or "xxxxx\n"

This requires heuristic detection rather than simple magic matching.

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
