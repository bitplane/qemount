---
title: LZX
created: 1995
discontinued: 1997
detect:
  - offset: 0
    type: string
    value: "LZX"
---

# LZX (Amiga)

LZX was created by Jonathan Forbes in 1995 for the Amiga. It offered
excellent compression ratios for its time and was widely used in the
Amiga scene. The compression algorithm was later licensed by Microsoft
for use in their CAB format (the "LZX" method in Cabinet files),
though the archive format itself is different.

## Characteristics

- LZ77 + entropy coding
- Good compression ratios (competitive with RAR at the time)
- Amiga-specific metadata (protection bits, file comments)
- Multiple compression methods
- Archive comments

## Structure

```
Header:
  Offset  Size  Field
  0       3     Magic ("LZX")
  ...
```

## History

- 1995: LZX released for Amiga
- 1996: Microsoft licenses the algorithm for CAB/CHM
- 1997: Development ceases (Forbes reportedly joined Microsoft)
- Algorithm lives on in Windows CAB, CHM, WIM, and Xbox formats

## File Extension

`.lzx`

## References

- Not to be confused with Microsoft's LZX compression method, which
  uses the same algorithm but a different container format
