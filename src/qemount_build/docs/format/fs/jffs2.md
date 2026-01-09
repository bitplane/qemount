---
title: JFFS2
created: 2001
related:
  - format/fs/ubifs
  - format/fs/squashfs
detect:
  - offset: 0
    type: le16
    value: 0x1985
  - offset: 0
    type: be16
    value: 0x1985
---

# JFFS2 (Journalling Flash File System 2)

JFFS2 was developed by Red Hat and released in 2001. It's designed
specifically for raw flash memory devices (NOR and NAND), providing
wear leveling and power-fail safety.

## Characteristics

- Log-structured design
- Wear leveling built-in
- Power-fail safe
- Compression support (zlib, rtime, lzo)
- No erase block management overhead
- Direct flash access (no FTL)
- Garbage collection

## Structure

- Magic 0x1985 in node headers
- No superblock (scans entire flash)
- Node-based structure
- Dirent nodes for directory entries
- Inode nodes for file data
- Clean/dirty marker nodes

## Node Types

| Type | Purpose |
|------|---------|
| DIRENT | Directory entry |
| INODE | File data/metadata |
| CLEAN | Erase block is clean |
| PADDING | Fill unused space |
| SUMMARY | Speed up mount |
| XATTR | Extended attributes |

## Key Features

- **Wear Leveling**: Automatic across all blocks
- **Compression**: Per-node compression
- **Garbage Collection**: Background space reclaim
- **Write Buffers**: Efficient small writes
- **Summary Nodes**: Faster mount times

## Limitations

- Slow mount on large filesystems (must scan all)
- RAM usage scales with flash size
- NAND performance issues on large devices
- Superseded by UBIFS for large NAND

## vs UBIFS

| Feature | JFFS2 | UBIFS |
|---------|-------|-------|
| Flash type | NOR/NAND | NAND (UBI) |
| Mount speed | Slow | Fast |
| RAM usage | High | Constant |
| Write-back | No | Yes |
| Best for | Small NOR | Large NAND |

## Linux Support

Linux has full JFFS2 support (fs/jffs2/). Used extensively in
embedded Linux systems, OpenWrt routers, and IoT devices.

## Creating Images

```sh
mkfs.jffs2 -d rootfs/ -o image.jffs2 -e 128KiB -n
```
