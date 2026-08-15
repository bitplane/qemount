---
title: freeze
created: 1992
discontinued: 1993
related:
  - format/arc/compress
  - format/arc/gzip
detect:
  any:
    - offset: 0
      type: le16
      value: 0x9f1f
      name: freeze_v2
    - offset: 0
      type: le16
      value: 0x9e1f
      name: freeze_v1
---

# freeze

freeze was created by Leonid Broukhis in 1992 as an improvement over
Unix compress. It used LZ77 with an adaptive Huffman coding scheme.
Superseded by gzip, which offered better compression and became the
Unix standard.

## Characteristics

- LZ77 + adaptive Huffman coding
- Better compression than compress(1)
- Drop-in replacement for compress
- Two versions with different magic bytes

## Detection

| Magic | Version | Notes |
|-------|---------|-------|
| `1F 9F` | 2.1 | Standard freeze |
| `1F 9E` | 1.0 | Also matches gzip 0.5 (ambiguous) |

The two-byte magic follows the Unix compress convention of `1F xx`.

## File Extension

`.F`
