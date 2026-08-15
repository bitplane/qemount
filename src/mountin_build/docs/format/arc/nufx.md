---
title: NuFX (ShrinkIt)
created: 1989
related:
  - format/arc/lha
detect:
  any:
    - offset: 0
      type: string
      value: "NuFile"
    - offset: 0
      type: string
      value: "N\xf5F\xe9l\xe5"
---

# NuFX (ShrinkIt / NuFile Exchange)

NuFX was created by Andy Nicholas in 1989 as the archive format for
ShrinkIt on the Apple II. It became the standard archive format for
Apple II software distribution and preservation. The format preserves
Apple II-specific metadata (ProDOS file types, aux types).

## Characteristics

- LZW/1 and LZW/2 compression
- Preserves ProDOS file type and auxiliary type
- Resource fork support (GS/ShrinkIt)
- Disk image archiving
- Multiple threads per record (data fork, resource fork, comments)
- CRC-16 checksums

## Structure

```
Master header:
  Offset  Size  Field
  0       6     Magic ("NuFile" or high-bit-set variant)
  6       2     Master CRC
  8       4     Total records
  12      8     Archive creation/modification dates
  ...
```

Each record has a header starting with `NuFX` followed by thread
headers describing the data, resource fork, filename, and comment
threads.

## Detection

Two magic variants exist: standard ASCII `NuFile` and high-bit-set
`N\xF5F\xE9l\xE5` (Apple II character set convention).

## File Extensions

| Extension | Usage |
|-----------|-------|
| `.shk` | ShrinkIt archive |
| `.sdk` | ShrinkIt disk image |
| `.bxy` | Binary II + ShrinkIt |

## References

- [NuLib2](https://github.com/fadden/nulib2) — open source NuFX library
- [CiderPress](https://github.com/fadden/ciderpress) — Apple II archive tool
