---
title: QNX6
created: 2004
related:
  - fs/qnx4
detect:
  - offset: 0x2000
    type: le32
    value: 0x68191122
---

# QNX6 Filesystem (Power-Safe)

The QNX6 filesystem, also known as Power-Safe filesystem, was introduced
with QNX Neutrino 6.4. It features copy-on-write transactions and dual
superblocks for reliability in embedded and automotive systems.

## Characteristics

- Copy-on-write transactions
- Dual superblocks (A/B)
- Atomic updates
- Power-fail safe
- Maximum file size: 512 GB
- Maximum volume size: 16 TB (32-bit), 512 TB (64-bit)
- Transparent endianness

## Structure

- Boot block at offset 0 (0x2000 bytes)
- Superblock at offset 0x2000
- Magic 0x68191122 in superblock
- Secondary superblock at end of device
- B-tree based metadata
- Serial numbers track active superblock

## Power-Safe Design

Uses A/B superblock pattern:
1. Write new data to free space
2. Update inactive superblock
3. Increment serial number
4. New superblock becomes active
5. No partial writes possible

## Endianness Support

- Can create little or big endian filesystems
- Linux driver auto-detects endianness
- Cross-platform development support

## Use Cases

- Automotive (Audi MMI, etc.)
- Industrial control systems
- Medical devices
- Any power-critical embedded system

## Linux Support

Linux has read-only QNX6 support (fs/qnx6/).
Handles both endianness variants transparently.
