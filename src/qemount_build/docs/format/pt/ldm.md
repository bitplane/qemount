---
title: LDM
created: 2000
related:
  - format/pt/gpt
  - format/pt/mbr
detect:
  - offset: 0
    type: string
    value: "PRIVHEAD"
    name: ldm_signature
---

# LDM (Logical Disk Manager)

LDM is Microsoft's dynamic disk system introduced in Windows 2000.
It provides software RAID, spanning, and dynamic volume management.

## Characteristics

- Software RAID (0, 1, 5)
- Spanned volumes across disks
- Striped volumes
- Mirrored volumes
- Dynamic resizing
- Database stored at end of disk

## Structure

LDM uses the last 1MB of the disk for its database:

```
Offset from end  Description
-1MB             Private headers (PRIVHEAD)
...              Table of contents (TOCBLOCK)
...              Volume manager database (VMDB)
...              Volume log (VBLK)
```

**PRIVHEAD (512 bytes)**
```
Offset  Size  Description
0       8     Signature "PRIVHEAD"
8       4     Unknown
12      4     Version
16      4     Unknown
...
48      64    Disk GUID
112     64    Host GUID
176     64    Disk group GUID
...
```

**TOCBLOCK**
```
Offset  Size  Description
0       8     Signature "TOCBLOCK"
8       ...   Table entries
```

**VMDB**
```
Offset  Size  Description
0       4     Signature "VMDB"
4       4     Sequence number
...
```

## Volume Types

| Type     | Description                      |
|----------|----------------------------------|
| Simple   | Single partition span            |
| Spanned  | Multiple partitions concatenated |
| Striped  | RAID-0                           |
| Mirrored | RAID-1                           |
| RAID-5   | Parity striping                  |

## Linux Support

Linux has read-only LDM support (CONFIG_LDM_PARTITION).
Windows Vista+ uses different format for some features.
