---
title: ZPAQ
created: 2009
detect:
  any:
    - offset: 0
      type: string
      value: "zPQ"
    - offset: 0
      type: string
      value: "7kSt"
---

# ZPAQ

ZPAQ was created by Matt Mahoney in 2009. It is a journaling archiver
designed for incremental backups with extreme compression ratios. The
format embeds the decompression algorithm in the archive itself, making
it future-proof — any ZPAQ archive can be decompressed even if the
compression method evolves.

## Characteristics

- Self-describing compression (algorithm embedded in archive)
- Journaling / incremental backup model
- Deduplication at block level
- Extreme compression ratios (often best-in-class)
- Context mixing compression
- Multi-threaded compression/decompression

## Detection

| Magic | Format |
|-------|--------|
| `zPQ` at offset 0 | ZPAQ stream |
| `7kSt` at offset 0 | ZPAQ file (journaling format) |

## Structure

ZPAQ streams consist of blocks, each containing:
- A header with the compression model (bytecode for a virtual machine)
- Compressed data segments
- SHA-1 checksums

The journaling format (`7kSt`) adds an index of file metadata and
incremental update records.

## File Extension

`.zpaq`

## References

- [ZPAQ](http://mattmahoney.net/dc/zpaq.html)
- Often wins compression benchmarks on large datasets
