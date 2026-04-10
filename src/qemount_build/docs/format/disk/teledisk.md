---
title: TeleDisk
created: 1985
discontinued: 2003
related:
  - format/disk/imd
  - format/disk/raw
detect:
  any:
    - offset: 0
      type: string
      value: "TD\x00"
      name: uncompressed
    - offset: 0
      type: string
      value: "td\x00"
      name: compressed
---

# TeleDisk

TeleDisk was created by Sydex around 1985 for transmitting floppy disk
images over modems and BBS systems. It was one of the earliest floppy
disk imaging tools and could handle many non-standard disk formats. The
format is important for vintage computing preservation.

## Characteristics

- Optional LZSS compression (uppercase TD = raw, lowercase td = compressed)
- Per-track sector data with geometry info
- Supports 5.25" and 3.5" media
- Handles non-standard sector sizes and interleaving
- CRC checksums for data integrity
- Optional comment block
- "Advanced compression" mode (td) vs normal (TD)

## Detection

| Magic | Format |
|-------|--------|
| `TD\x00` | Uncompressed TeleDisk |
| `td\x00` | Compressed TeleDisk (LZSS) |

## Structure

```
Header (12 bytes):
  Offset  Size  Field
  0       2     Magic ("TD" or "td")
  2       1     Zero
  3       1     Volume sequence
  4       1     Check signature
  5       1     TeleDisk version
  6       1     Source data rate
  7       1     Drive type
  8       1     Stepping
  9       1     DOS allocation flag
  10      2     CRC-16 of header
```

Optional comment block follows, then per-track data.

## File Extension

`.td0`

## References

- Sydex (Sydney Dataworks, www.sydex.com)
- Superseded by ImageDisk (IMD) for modern preservation work
