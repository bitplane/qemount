---
title: Quake PAK
created: 1996
detect:
  - offset: 0
    type: string
    value: "PACK"
---

# Quake PAK

The PAK format was created by id Software for Quake (1996). It is a
simple uncompressed archive used to bundle game assets (maps, textures,
models, sounds). The format was adopted by many Quake-engine games and
remains in use by Source engine games.

## Characteristics

- Simple flat archive (no compression)
- 56-byte filename entries with absolute offsets
- File table at end of archive (offset stored in header)
- Fast random access
- No encryption or checksums

## Structure

```
Header (12 bytes):
  Offset  Size  Field
  0       4     Magic ("PACK")
  4       4     File table offset (LE32)
  8       4     File table size (LE32)

File table entries (64 bytes each):
  Offset  Size  Field
  0       56    Filename (null-terminated, with path)
  56      4     File offset (LE32)
  60      4     File size (LE32)
```

Number of files = file table size / 64.

## Detection

Note: the `PACK` magic at offset 0 is shared with other formats
(notably Git pack files use `PACK` followed by a big-endian version).
Quake PAK can be distinguished by the little-endian file table offset
at byte 4 being a large value (pointing to end of file).

## Games Using PAK

- Quake (1996), Quake II (1997), Quake III Arena (1999)
- Half-Life (1998) — uses a variant called GCF/VPK
- Many Quake-engine licensees

## File Extension

`.pak`
