---
title: MPQ
created: 1996
detect:
  - offset: 0
    type: string
    value: "MPQ\x1a"
---

# MPQ (Mo'PaQ / Mike O'Brien Pack)

MPQ was created by Mike O'Brien at Blizzard Entertainment in 1996 for
Diablo. It became Blizzard's standard archive format, used across
StarCraft, Diablo II, Warcraft III, and World of Warcraft. Named after
its creator ("Mike O'Brien Pack").

## Characteristics

- Hash table-based file lookup (no sequential scan)
- Per-file compression (zlib, bzip2, LZMA, Huffman, ADPCM)
- Per-file encryption
- Locale and platform variants per file
- Patch archives (overlay previous archives)
- Digital signatures
- Sector-based storage for streaming

## Structure

```
Header:
  Offset  Size  Field
  0       4     Magic ("MPQ\x1A")
  4       4     Header size
  8       4     Archive size
  12      2     Format version
  14      2     Sector size shift
  16      4     Hash table offset
  20      4     Block table offset
  24      4     Hash table entries
  28      4     Block table entries
```

## Versions

| Version | Year | Games |
|---------|------|-------|
| 1 | 1996 | Diablo, StarCraft, Diablo II |
| 2 | 2003 | Warcraft III: TFT |
| 3 | 2007 | WoW: Burning Crusade |
| 4 | 2010 | StarCraft II (superseded by CASC) |

## File Extension

`.mpq`

## References

- [StormLib](https://github.com/ladislav-zezula/StormLib) — open source MPQ library
