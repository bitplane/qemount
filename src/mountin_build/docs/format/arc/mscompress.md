---
title: Microsoft COMPRESS
created: 1990
detect:
  any:
    - offset: 0
      type: string
      value: "SZDD"
    - offset: 0
      type: string
      value: "KWAJ"
---

# Microsoft COMPRESS (SZDD/KWAJ)

Microsoft COMPRESS was shipped with MS-DOS 5.0 and Windows 3.0 (1990-1991).
It compressed files for distribution on floppy disks, replacing the last
character of the file extension with an underscore (e.g. `FOO.DL_` for
`FOO.DLL`). Expanded with the `EXPAND.EXE` utility.

## Characteristics

- Single-file compression
- LZSS-based compression (SZDD)
- LZ + Huffman compression (KWAJ, better ratio)
- Filename stored in header
- Used extensively on Windows installation media

## Detection

Three format variants:

| Magic | Offset | Format |
|-------|--------|--------|
| `SZDD\x88\xF0\x27\x33` | 0 | Standard (MS-DOS 5+) |
| `KWAJ\x88\xF0\x27` | 0 | Improved (MS-DOS 6+) |
| `SZ\x20\x88\xF0\x27` | 0 | QBasic variant |

SZDD stores the original filename's last character at offset 9.

## Structure (SZDD)

```
Header:
  Offset  Size  Field
  0       4     Magic ("SZDD")
  4       4     Signature (88 F0 27 33)
  8       1     Compression method ('A')
  9       1     Last char of original filename
  10      4     Uncompressed size
```

## File Extension

`??_` (last character replaced with underscore), e.g. `.DL_`, `.EX_`

## References

- Standard tool on every Windows install disc from 3.0 through XP
