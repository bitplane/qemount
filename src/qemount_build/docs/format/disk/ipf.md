---
title: IPF (CAPS/SPS)
created: 2001
related:
  - format/disk/raw
detect:
  - offset: 0
    type: string
    value: "CAPS"
---

# IPF (Interchangeable Preservation Format)

IPF was created around 2001 by the Software Preservation Society (SPS,
formerly Classic Amiga Preservation Society / CAPS). It is the standard
format for preserving copy-protected floppy disks, capturing not just
sector data but the physical flux timing and encoding that copy protection
schemes relied upon.

## Characteristics

- Preserves copy protection schemes
- Records flux timing information
- Supports Amiga, Atari ST, PC, and other platforms
- Per-track encoding and timing data
- Block-level record structure
- Used by most Amiga emulators (WinUAE, FS-UAE)

## Structure

The file is a sequence of typed records:

```
Record header:
  Offset  Size  Field
  0       4     Record type ID (ASCII)
  4       4     Record length
  8       4     CRC-32
  12      var   Record data
```

The first record is always `CAPS` (the file magic). Subsequent records
include:

| Type | Description |
|------|-------------|
| `CAPS` | File header |
| `INFO` | Media info (platform, disk type, dates) |
| `IMGE` | Track image descriptor |
| `DATA` | Track data |
| `CTEX` | Comment text |
| `CTEI` | Creator info |

## File Extension

`.ipf`

## References

- [Software Preservation Society](http://www.softpres.org/)
- [CAPS/IPF library](https://github.com/keirf/caps-ipf)
