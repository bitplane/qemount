---
title: UBI
type: pt
created: 2006
related:
  - fs/ubifs
  - fs/jffs2
detect:
  - offset: 0
    type: be32
    value: 0x55424923
    name: ubi_magic
    then:
      - offset: 4
        type: u8
        name: version
---

# UBI (Unsorted Block Images)

UBI is a volume management layer for raw NAND flash, developed as part of
the Linux MTD subsystem. It sits between the MTD layer and filesystems
like UBIFS, providing wear leveling, bad block management, and volume
abstraction.

## Characteristics

- Volume management for raw flash
- Wear leveling across entire flash
- Bad block handling
- Logical erase blocks (LEBs)
- Multiple volumes per device
- Not a filesystem itself

## Structure

- Magic "UBI#" (0x55424923) at erase block headers
- EC (Erase Counter) header at start of each PEB
- VID (Volume ID) header follows EC header
- Volume table in reserved LEBs
- Data area in remaining space

## Headers

**EC Header (64 bytes):**
- Magic: 0x55424923 ("UBI#")
- Version
- Erase counter
- VID header offset
- Data offset
- CRC

**VID Header:**
- Magic: 0x55424921 ("UBI!")
- Volume ID
- LEB number
- Data size
- CRC

## Key Features

- **Wear Leveling**: Spreads erases across all blocks
- **Bad Block Management**: Transparent remapping
- **Atomic Updates**: Via LEB change operation
- **Volume Resize**: Dynamic volume sizing
- **Static Volumes**: Read-only, CRC protected

## vs Raw MTD

| Feature | Raw MTD | UBI |
|---------|---------|-----|
| Wear leveling | No | Yes |
| Bad blocks | Manual | Automatic |
| Volumes | No | Yes |
| Overhead | None | ~1-2% |

## Stack

```
┌─────────────┐
│   UBIFS     │  (or JFFS2, SquashFS)
├─────────────┤
│    UBI      │  ← Volume management
├─────────────┤
│    MTD      │  (Memory Technology Device)
├─────────────┤
│ NAND Flash  │
└─────────────┘
```

## Linux Support

UBI is part of the Linux kernel MTD subsystem (drivers/mtd/ubi/).
Tools in mtd-utils: `ubiformat`, `ubiattach`, `ubimkvol`, `ubinize`.

## Image Creation

```sh
# Create ubinize config
cat > ubi.cfg << EOF
[rootfs]
mode=ubi
image=rootfs.ubifs
vol_id=0
vol_type=dynamic
vol_name=rootfs
EOF

# Create UBI image
ubinize -o image.ubi -m 2048 -p 128KiB ubi.cfg
```
