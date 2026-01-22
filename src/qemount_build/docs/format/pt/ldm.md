---
title: LDM
created: 2000
priority: -10
related:
  - format/pt/gpt
  - format/pt/mbr
detect:
  - offset: 0xC00
    type: string
    value: "PRIVHEAD"
---

# LDM (Logical Disk Manager)

Microsoft Windows dynamic disk system introduced in Windows 2000.
Provides software RAID, spanning, and dynamic volume management.

## Detection

PRIVHEAD magic "PRIVHEAD" at sector 6 (offset 0xC00 = 3072).

Note: MBR partition type 0x42 also indicates LDM.

## Database Layout

LDM database is 1 MiB (2048 sectors). Sector offsets within database:

| Sector | Structure | Description |
|--------|-----------|-------------|
| 6      | PRIVHEAD  | Primary private header |
| 1, 2   | TOCBLOCK  | Primary table of contents |
| 17     | VMDB      | Volume manager database header |
| varies | VBLK      | Volume block records |
| 1856   | PRIVHEAD  | Backup private header |
| 2045-2046 | TOCBLOCK | Backup table of contents |
| 2047   | PRIVHEAD  | Backup private header |

## Structure

**PRIVHEAD (at sector 6)**
```
Offset  Size  Type   Description
0x00    8     str    Magic "PRIVHEAD"
0x0C    2     BE16   Version major (2)
0x0E    2     BE16   Version minor (11=Win2k/XP, 12=Vista)
0x30    36    str    Disk GUID
0x11B   8     BE64   Logical disk start (sectors)
0x123   8     BE64   Logical disk size (sectors)
0x12B   8     BE64   Config start (sectors)
0x133   8     BE64   Config size (sectors, normally 2048)
```

**TOCBLOCK (at sectors 1, 2)**
```
Offset  Size  Type   Description
0x00    8     str    Magic "TOCBLOCK"
0x24    10    str    Bitmap1 name ("config")
0x2E    8     BE64   Bitmap1 start
0x36    8     BE64   Bitmap1 size
0x46    10    str    Bitmap2 name ("log")
0x50    8     BE64   Bitmap2 start
0x58    8     BE64   Bitmap2 size
```

**VMDB (at sector 17)**
```
Offset  Size  Type   Description
0x00    4     str    Magic "VMDB"
0x04    4     BE32   Last VBLK sequence
0x08    4     BE32   VBLK size
0x0C    4     BE32   VBLK offset
0x12    2     BE16   Version major (4)
0x14    2     BE16   Version minor (10)
```

**VBLK (Volume Block Records)**
```
Offset  Size  Type   Description
0x00    4     str    Magic "VBLK"
0x04    4     BE32   Sequence number
0x08    4     BE32   Group number
0x0D    1     u8     Record type
```

VBLK record types:
- 0x32: Component (version 3)
- 0x33: Partition (version 3)
- 0x34: Disk (version 3)
- 0x35: Disk Group (version 3)
- 0x44: Disk (version 4)
- 0x45: Disk Group (version 4)
- 0x51: Volume (version 5)

## Volume Types

| Type     | Component | Description |
|----------|-----------|-------------|
| Simple   | 0x02      | Single partition |
| Spanned  | 0x01      | Concatenated partitions |
| Striped  | 0x01      | RAID-0 |
| Mirrored | 0x02      | RAID-1 |
| RAID-5   | 0x03      | Parity striping |

## Multi-Disk Considerations

LDM volumes can span multiple physical disks. Each disk has its own
LDM database with disk GUIDs linking them together. Full support
requires reading databases from all member disks.

## Linux Support

Linux has read-only LDM support (CONFIG_LDM_PARTITION).
Only simple volumes on single disks are fully supported.
