---
title: UBIFS
created: 2008
related:
  - format/pt/ubi
  - format/fs/jffs2
  - format/fs/f2fs
detect:
  - offset: 0
    type: le32
    value: 0x06101831
    name: ubifs_node_magic
---

# UBIFS (Unsorted Block Image File System)

UBIFS was developed by Nokia with help from the University of Szeged,
released in Linux 2.6.27 (2008). It's designed for raw NAND flash and
requires the UBI (Unsorted Block Images) layer.

## Characteristics

- Designed for large NAND flash
- Requires UBI volume management layer
- Constant mount time (unlike JFFS2)
- Write-back support
- On-the-fly compression
- Maximum file size: 2 TB
- Constant RAM usage regardless of flash size

## Structure

- Magic 0x06101831 in UBIFS nodes
- Superblock node contains volume info
- Master node for filesystem state
- Index tree (TNC - Tree Node Cache)
- LPT (LEB Properties Tree)
- Journal for crash recovery

## UBI Layer

UBIFS sits on top of UBI, which provides:
- Logical erase blocks (LEBs)
- Wear leveling
- Bad block management
- Volume abstraction

```
┌─────────────┐
│   UBIFS     │
├─────────────┤
│    UBI      │
├─────────────┤
│  MTD/NAND   │
└─────────────┘
```

## Key Features

- **Write-back**: Caches writes for efficiency
- **Compression**: LZO, ZLIB, ZSTD
- **Fast Mount**: Index tree, not full scan
- **Authenticated**: HMAC support
- **Power Cut Safety**: Journal + atomic commits

## vs JFFS2

| Feature | UBIFS | JFFS2 |
|---------|-------|-------|
| Mount time | O(1) | O(n) |
| RAM usage | Constant | Proportional |
| Write-back | Yes | No |
| Compression | Better | Good |
| Bad blocks | UBI handles | Internal |

## Linux Support

Linux has full UBIFS support (fs/ubifs/). Standard for modern
embedded Linux on NAND flash devices.

## Creating Images

```sh
# Create UBI image
ubinize -o ubi.img -m 2048 -p 128KiB ubinize.cfg

# Mount on target
ubiattach /dev/ubi_ctrl -m 0
mount -t ubifs ubi0:rootfs /mnt
```
