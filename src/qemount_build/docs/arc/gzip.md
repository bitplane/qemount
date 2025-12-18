---
title: gzip
created: 1992
related:
  - arc/tar
detect:
  - offset: 0
    type: le16
    value: 0x8b1f
    name: gzip_magic
---

# gzip (GNU zip)

gzip was created by Jean-loup Gailly and Mark Adler in 1992 as a free
replacement for the Unix compress utility. It's technically a compression
format, not an archive - it compresses a single stream.

## Characteristics

- Single file compression (not an archive)
- DEFLATE algorithm (LZ77 + Huffman)
- CRC32 integrity check
- Original filename/timestamp preserved
- Usually paired with tar for archives

## Structure

**Header (10+ bytes):**
```
Offset  Size  Field
0       2     Magic (0x1f 0x8b)
2       1     Compression method (8 = deflate)
3       1     Flags
4       4     Modification time (Unix)
8       1     Extra flags
9       1     OS
```

**Flags (byte 3):**
| Bit | Meaning |
|-----|---------|
| 0 | FTEXT - ASCII text |
| 1 | FHCRC - Header CRC16 |
| 2 | FEXTRA - Extra field |
| 3 | FNAME - Original filename |
| 4 | FCOMMENT - Comment |

**Footer (8 bytes):**
```
Offset  Size  Field
0       4     CRC32
4       4     Original size (mod 2^32)
```

## OS Values

| Value | OS |
|-------|-----|
| 0 | FAT (DOS/Windows) |
| 3 | Unix |
| 7 | Macintosh |
| 11 | NTFS |
| 255 | Unknown |

## Related Formats

- **zlib** - gzip without header/trailer, for embedding
- **DEFLATE** - raw compression, no wrapper
- **pigz** - parallel gzip
- **bgzip** - block gzip (random access)
