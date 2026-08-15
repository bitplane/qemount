---
title: Acorn EESOX
created: 1990
priority: -10
related:
  - format/pt/acorn/adfs
detect:
  - offset: 0xE00
    type: xor
    length: 256
    key: "Neil Critchell  "
    then:
      - offset: 0
        type: string
        value: "Eesox"
---

# Acorn EESOX Partition Table

EESOX SCSI partition format for Acorn RISC OS.

## Detection

XOR-encrypted partition table at sector 7 (offset 0xE00 = 7 * 512):
- Decryption key: "Neil Critchell  " (16 bytes, repeating)
- After decryption, should start with magic "Eesox"

## Structure

**Encrypted Block (sector 7)**
```
After XOR decryption with key "Neil Critchell  ":
Offset  Size  Description
0       5     Magic "Eesox"
...     ...   Partition entries
```

## Partition Layout

Up to 8 partitions. Each partition entry contains:
- 1 byte: status (active/inactive)
- 4 bytes: start sector (LE32)
- 4 bytes: size in sectors (LE32)
