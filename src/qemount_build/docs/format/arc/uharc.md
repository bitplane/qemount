---
title: UHARC
created: 1996
discontinued: 2005
detect:
  - offset: 0
    type: string
    value: "UHA"
---

# UHARC

UHARC was created by Uwe Herklotz in 1996. It was known for excellent
compression ratios, often beating RAR and ACE. Popular in the demo scene
and on BBS systems where every byte counted. The compression algorithm
is proprietary.

## Characteristics

- Very high compression ratios
- PPM and LZH-based compression methods
- Dictionary sizes up to 64KB
- Solid archive support
- DOS, Windows, and OS/2 versions
- Proprietary compression (decompression-only source available)

## Structure

```
Header:
  Offset  Size  Field
  0       3     Magic ("UHA")
  ...
```

## File Extension

`.uha`

## References

- No longer actively developed
- Decompression source available for preservation
