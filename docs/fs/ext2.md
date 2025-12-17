---
title: ext2
created: 1993
related:
  - fs/ext3
  - fs/ext4
  - fs/minix
detect:
  - offset: 0x438
    type: le16
    value: 0xef53
    then:
      - offset: 0x45c
        type: le32
        mask: 0x4
        op: "^"
        value: 0
      - offset: 0x468
        type: string
        length: 16
        name: uuid
      - offset: 0x478
        type: string
        name: volume_name
---

# Second Extended Filesystem (ext2)

ext2 was designed by Rémy Card as a replacement for the extended filesystem
(ext) and released in 1993. It was the default Linux filesystem for many years
and remains useful for flash media and boot partitions where journaling overhead
is unwanted.

## Characteristics

- No journaling (faster writes, but fsck required after unclean unmount)
- Block sizes: 1024, 2048, or 4096 bytes
- Maximum file size: 16GB to 2TB (depends on block size)
- Maximum filesystem size: 2TB to 32TB
- Maximum filename: 255 bytes
- Timestamps: second precision (no sub-second)

## Structure

- Superblock at offset 1024 (0x400)
- Magic number 0xef53 at offset 0x438
- Block groups with inode tables and data blocks
- Inode-based file metadata
- Bitmap allocation for blocks and inodes

## Detection

Distinguished from ext3/ext4 by the absence of the journal feature flag
(bit 0x4) in the compatible features field at offset 0x45c.

## Use Cases

- Boot partitions (/boot)
- USB flash drives (reduces write wear)
- Embedded systems with limited resources
- Recovery environments
