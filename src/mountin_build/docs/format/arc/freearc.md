---
title: FreeArc
created: 2004
related:
  - format/arc/7z
detect:
  - offset: 0
    type: string
    value: "ArC\x01"
---

# FreeArc

FreeArc was created by Bulat Ziganshin starting in 2004. It is an open
source archiver focused on achieving the best possible compression ratios
by combining multiple algorithms. It consistently placed highly in
compression benchmarks.

## Characteristics

- Multiple compression algorithms (LZMA, PPMD, GRZip, etc.)
- Solid archives
- Encryption (AES-256, Blowfish, Twofish, Serpent)
- Recovery records
- Self-extracting archives
- Written in Haskell (unusual for an archiver)

## Structure

```
Header:
  Offset  Size  Field
  0       4     Magic ("ArC\x01" = 41 72 43 01)
  ...
```

## File Extension

`.arc` (conflicts with SEA ARC format — distinguished by magic bytes)

## References

- [FreeArc](http://freearc.org)
