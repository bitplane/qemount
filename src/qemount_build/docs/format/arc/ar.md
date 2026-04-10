---
title: ar
created: 1971
related:
  - format/arc/tar
detect:
  - offset: 0
    type: string
    value: "!<arch>\n"
---

# ar (Unix Archive)

ar is the oldest Unix archive format, present since First Edition Unix
(1971). It predates tar by eight years. Today it is primarily used for
static libraries (.a files) and as the outer container for Debian
packages (.deb).

## Characteristics

- Simple flat archive (no directories)
- No compression (use with gzip/xz externally)
- 60-byte fixed-size file headers
- Filenames limited to 16 characters (extended name schemes exist)
- No permission preservation beyond mode bits

## Structure

```
Global header:  "!<arch>\n"  (8 bytes)

Per-file header (60 bytes):
  Offset  Size  Field
  0       16    Filename (space-padded, "/" terminated)
  16      12    Modification time (decimal)
  28      6     Owner ID (decimal)
  34      6     Group ID (decimal)
  40      8     File mode (octal)
  48      10    File size (decimal)
  58      2     End marker ("`\n")
```

Files are padded to 2-byte alignment.

## Variants

| Variant | Long names | Used by |
|---------|-----------|---------|
| System V / GNU | `//` string table | Linux (.a, .deb) |
| BSD | `#1/` prefix + inline name | macOS (.a) |
| Common | 16-char limit | Original |

## Debian Packages

`.deb` files are ar archives containing:
- `debian-binary` — version string ("2.0")
- `control.tar.xz` — package metadata
- `data.tar.xz` — installed files
