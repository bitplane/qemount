---
title: tar
created: 1979
related:
  - arc/cpio
detect:
  any:
    - offset: 257
      type: string
      value: "ustar"
      name: ustar_magic
    - offset: 257
      type: string
      value: "ustar "
      name: gnu_magic
---

# tar (Tape Archive)

tar was created for Unix V7 in 1979 to write files to tape. It remains
the standard archive format for Unix/Linux systems.

## Characteristics

- Sequential file storage
- Preserves Unix permissions, ownership, timestamps
- No built-in compression (use gzip, xz, etc.)
- 512-byte block alignment
- Multiple format variants

## Formats

| Format | Magic | Features |
|--------|-------|----------|
| V7 | (none) | Original, 100-char paths |
| POSIX ustar | "ustar\0" | 256-char paths, device files |
| GNU tar | "ustar " | Long paths, sparse files |
| pax | "ustar\0" | Extended headers, unlimited |

## Structure

**Header (512 bytes):**
```
Offset  Size  Field
0       100   Filename
100     8     Mode (octal)
108     8     UID (octal)
116     8     GID (octal)
124     12    Size (octal)
136     12    Mtime (octal)
148     8     Checksum
156     1     Type flag
157     100   Link name
257     6     Magic ("ustar")
263     2     Version
265     32    Owner name
297     32    Group name
329     8     Dev major
337     8     Dev minor
345     155   Prefix (for long names)
```

## Type Flags

| Flag | Type |
|------|------|
| '0' or '\0' | Regular file |
| '1' | Hard link |
| '2' | Symbolic link |
| '3' | Character device |
| '4' | Block device |
| '5' | Directory |
| '6' | FIFO |

## Common Compression

- `.tar.gz` / `.tgz` - gzip
- `.tar.bz2` / `.tbz` - bzip2
- `.tar.xz` / `.txz` - xz/lzma
- `.tar.zst` - zstandard
