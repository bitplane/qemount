---
title: ImageDisk
created: 2006
related:
  - format/disk/raw
detect:
  - offset: 0
    type: string
    value: "IMD "
---

# ImageDisk (IMD)

ImageDisk was created by Dave Dunfield in 2006 for preserving floppy disk
images, particularly from vintage computers. Unlike raw sector dumps, IMD
records the physical disk geometry, sector numbering, and encoding mode
for each track, making it invaluable for archiving non-standard and
copy-protected floppy formats.

## Characteristics

- Per-track geometry recording (sector size, count, encoding)
- Supports FM and MFM encoding modes
- Records sector numbering maps (handles non-sequential sectors)
- Handles bad sectors and missing data
- ASCII comment header
- Supports 8", 5.25", and 3.5" media
- Widely used in vintage computing preservation

## Structure

```
Header:
  "IMD " followed by version, date, and newline-terminated comment
  Comment terminated by 0x1A (EOF marker)

Per-track records:
  Mode byte (FM/MFM, data rate)
  Cylinder number
  Head number
  Sector count
  Sector size code
  Sector numbering map
  Sector data (with type bytes indicating normal/compressed/deleted/error)
```

## Sector Data Types

| Type | Meaning |
|------|---------|
| 0x00 | Unavailable |
| 0x01 | Normal data |
| 0x02 | Compressed (all bytes identical) |
| 0x03 | Deleted data |
| 0x04 | Deleted + compressed |
| 0x05 | Error data |
| 0x06 | Error + compressed |

## File Extension

`.imd`

## References

- [ImageDisk](http://dunfield.classiccmp.org/img/index.htm)
