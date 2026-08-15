---
title: BinHex
created: 1985
discontinued: 2003
detect:
  - offset: 0
    type: string
    value: "(This file must be converted with BinHex"
---

# BinHex

BinHex 4.0 was created by Yves Lempereur in 1985 for encoding Macintosh
files (with their resource forks and Finder metadata) into 7-bit ASCII
for transmission over email and Usenet. It was the standard Mac file
encoding before MIME and Base64 became universal.

## Characteristics

- Encodes data fork, resource fork, and Finder info
- 7-bit ASCII output (safe for email/Usenet)
- Run-length encoding + custom 6-to-8 bit encoding
- CRC-16 checksums
- Single-file encoding (not a multi-file archive)

## Structure

BinHex 4.0 files are text files beginning with:

```
(This file must be converted with BinHex 4.0)
:
[encoded data lines]
:
```

The encoded data contains:

| Field | Size | Description |
|-------|------|-------------|
| Name length | 1 | Pascal string length |
| Filename | var | Mac filename |
| Version | 1 | Always 0 |
| Type | 4 | Finder file type |
| Creator | 4 | Finder creator code |
| Flags | 2 | Finder flags |
| Data fork length | 4 | |
| Resource fork length | 4 | |
| Data fork | var | File data |
| Resource fork | var | Resource data |

CRC-16 checksums appear after the header, data fork, and resource fork.

## Versions

| Version | Extension | Notes |
|---------|-----------|-------|
| 1.0 | .hex | Hex encoding only |
| 2.0 | .hcx | Added compression |
| 4.0 | .hqx | Most common, RLE + 6-bit encoding |

Version 3.0 was skipped. "Version 5.0" is actually MacBinary.

## Detection

The text string at the start of the file is the detection signature.
It may be preceded by a small amount of whitespace or mail headers,
but typically appears within the first few hundred bytes.

## References

- [RFC 1741: MIME Encapsulation of BinHex-Encoded Files](https://www.rfc-editor.org/rfc/rfc1741)
