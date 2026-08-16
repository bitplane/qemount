---
title: MacBinary
created: 1985
discontinued: 2003
related:
  - format/arc/binhex
---

# MacBinary

MacBinary was designed by a community effort in 1985 as a binary encoding
for transferring Macintosh files (with their dual-fork structure) over
non-Mac systems. Unlike BinHex which uses 7-bit ASCII encoding, MacBinary
is a compact binary format requiring an 8-bit clean channel.

## Characteristics

- Preserves data fork, resource fork, and Finder metadata
- Binary format (more compact than BinHex)
- 128-byte header
- No compression
- Three versions with increasing metadata support

## Structure

```
Header (128 bytes):
  Offset  Size  Field
  0       1     Old version (must be 0)
  1       1     Filename length (1-63)
  2       63    Filename (Pascal string)
  65      4     File type (e.g. 'TEXT')
  69      4     Creator code (e.g. 'ttxt')
  73      1     Finder flags (high byte)
  74      1     Zero
  75      6     Vertical/horizontal position, window/folder ID
  81      1     Protected flag
  82      1     Zero
  83      4     Data fork length
  87      4     Resource fork length
  91      4     Creation date
  95      4     Modification date
  ...
  102     4     "mBIN" (MacBinary III only)
  122     1     Version (0x81=II, 0x82=III)
  124     2     CRC-16 of header (MacBinary II+)
```

Data fork follows at offset 128, padded to 128-byte boundary.
Resource fork follows after that.

## Detection

No strong magic for MacBinary I/II. MacBinary III has `mBIN` at offset
102. Earlier versions are detected by structural checks: byte 0 = 0x00,
byte 1 = 1-63, byte 74 = 0x00, byte 82 = 0x00, valid CRC at 124.

## Versions

| Version | Year | Additions |
|---------|------|-----------|
| I | 1985 | Basic format |
| II | 1987 | CRC-16, more Finder info |
| III | 1996 | `mBIN` signature, script/xflag |

## File Extension

`.bin`, `.macbin`
