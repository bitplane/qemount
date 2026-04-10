---
title: WAD
created: 1993
detect:
  any:
    - offset: 0
      type: string
      value: "IWAD"
    - offset: 0
      type: string
      value: "PWAD"
---

# WAD (Where's All the Data)

WAD was created by id Software for DOOM (1993). It is a simple lump-based
archive format that bundles game assets — levels, textures, sounds, sprites,
and music. The format enabled DOOM's legendary modding scene, as custom
PWADs could override or extend the base IWAD.

## Characteristics

- Uncompressed lump storage
- Directory at end of file
- 8-character lump names (uppercase)
- Two types: IWAD (complete game) and PWAD (patch/mod)
- Simple enough to edit with hex editors
- Marker lumps define groups (e.g. S_START/S_END for sprites)

## Structure

```
Header (12 bytes):
  Offset  Size  Field
  0       4     Magic ("IWAD" or "PWAD")
  4       4     Number of lumps (LE32)
  8       4     Directory offset (LE32)

Directory entries (16 bytes each):
  Offset  Size  Field
  0       4     Lump offset (LE32)
  4       4     Lump size (LE32)
  8       8     Lump name (null-padded ASCII)
```

## Types

| Magic | Type | Meaning |
|-------|------|---------|
| `IWAD` | Internal WAD | Complete game data (commercial) |
| `PWAD` | Patch WAD | Modifications, add-ons |

## Games Using WAD

- DOOM (1993), DOOM II (1994)
- Heretic (1994), Hexen (1995)
- Strife (1996)
- Thousands of community mods and total conversions

## File Extension

`.wad`
