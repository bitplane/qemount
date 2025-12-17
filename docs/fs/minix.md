---
title: Minix
type: fs
created: 1987
related:
  - fs/ext2
  - fs/v7
detect:
  any:
    - offset: 0x410
      type: le16
      value: 0x137f
    - offset: 0x410
      type: le16
      value: 0x138f
    - offset: 0x410
      type: le16
      value: 0x2468
    - offset: 0x410
      type: le16
      value: 0x2478
---

# Minix Filesystem

The Minix filesystem was created by Andrew S. Tanenbaum for MINIX in 1987.
It was the original filesystem for Linux (before ext was created) and heavily
influenced ext2's design.

## Characteristics

- Simple, educational design
- 16-bit or 30-bit block addresses (v1/v2)
- 14 or 30 character filenames
- Maximum file size: 64MB (v1) to 1GB (v2)
- Maximum volume size: 64MB (v1) to 1GB (v2)
- Inode-based structure
- Bitmap allocation

## Versions

| Magic | Version | Names | Notes |
|-------|---------|-------|-------|
| 0x137f | V1 | 14 char | Original |
| 0x138f | V1 | 30 char | Extended names |
| 0x2468 | V2 | 14 char | 30-bit blocks |
| 0x2478 | V2 | 30 char | 30-bit + long names |
| 0x4D5A | V3 | 60 char | Big files (MINIX 3) |

## Structure

- Boot block at sector 0
- Superblock at offset 1024 (0x400)
- Magic at offset 0x410 (16 bytes into superblock)
- Inode bitmap
- Zone (block) bitmap
- Inode table
- Data zones

## Historical Significance

- First filesystem used by Linux (0.01)
- Linus wrote ext to overcome its limitations
- Educational - still used for teaching OS concepts
- Clean, readable implementation

## Limitations

- Small maximum file/volume sizes
- No timestamps on directories (v1)
- Fixed inode count at creation
- No extended attributes
- No journaling
