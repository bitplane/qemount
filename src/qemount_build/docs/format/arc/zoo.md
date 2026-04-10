---
title: zoo
created: 1986
discontinued: 1991
detect:
  - offset: 20
    type: le32
    value: 0xfdc4a7dc
---

# zoo

zoo was created by Rahul Dhesi in 1986. It was popular on BBS systems
alongside ARC and ZIP, notable for being one of the few archive formats
available on both DOS and Unix systems. It used LZW compression (Lempel-
Ziv-Welch) similar to Unix compress.

## Characteristics

- LZW compression
- Cross-platform (DOS, Unix, VMS, Amiga, Atari ST)
- Long filename support (ahead of its time on DOS)
- Archive comments
- File versioning within archives
- Portable C implementation

## Structure

The file typically begins with a text description (e.g. "ZOO 2.10
Archive.") followed by the binary header.

```
Archive header (at variable offset, referenced from offset 20):
  Offset  Size  Field
  20      4     Magic (0xFDC4A7DC, little-endian)
  24      4     First directory entry offset
  28      4     Minus (negative offset to start)
  32      1     Major version
  33      1     Minor version
```

## Detection

The magic `0xFDC4A7DC` at offset 20 is distinctive. The first 20 bytes
are a human-readable text string (typically "ZOO 2.10 Archive.\x1A").

## File Extension

`.zoo`

## References

- Source code widely available (public domain)
