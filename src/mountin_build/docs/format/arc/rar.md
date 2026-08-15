---
title: RAR
created: 1993
detect:
  any:
    # RAR v1.5-v4
    - offset: 0
      type: string
      value: "Rar!\x1A\x07\x00"
    # RAR v5
    - offset: 0
      type: string
      value: "Rar!\x1A\x07\x01\x00"
---

# RAR (Roshal ARchive)

RAR was created by Eugene Roshal in 1993. It is a proprietary archive
format known for good compression ratios and recovery record support.
The decompression code (unrar) is freely available but the compression
algorithm is proprietary.

## Characteristics

- Solid compression
- Recovery records (repair damaged archives)
- Multi-volume spanning
- AES-128 (v4) / AES-256 (v5) encryption
- Unicode filenames
- NTFS streams and permissions

## Versions

| Version | Year | Magic | Notes |
|---------|------|-------|-------|
| 1.5-4.x | 1993-2012 | `Rar!\x1A\x07\x00` (7 bytes) | Most common |
| 5.0+ | 2013 | `Rar!\x1A\x07\x01\x00` (8 bytes) | New format |

## RAR5 Improvements

- AES-256 encryption (upgraded from AES-128)
- BLAKE2sp hashing
- Larger dictionary sizes (up to 1GB)
- Better recovery records
- Simplified header format (variable-length integers)
