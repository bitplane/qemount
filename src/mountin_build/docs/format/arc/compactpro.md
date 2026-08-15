---
title: Compact Pro
created: 1990
discontinued: 2002
related:
  - format/arc/binhex
---

# Compact Pro

Compact Pro was created by Bill Goodman around 1990 for the classic
Macintosh. It was popular for Mac file distribution before StuffIt
dominated, and was one of the few archivers that properly preserved
both data and resource forks.

## Characteristics

- Preserves Macintosh data fork, resource fork, and Finder metadata
- LZH-based compression
- Self-extracting archive support
- Segmented archives (spanning multiple floppies)
- Encryption support
- Directory structure preservation

## Detection

No reliable byte-level magic number. Identification on classic Mac OS
relied on Finder type/creator codes: type `PACT`, creator `CPCT`. The
first byte of the data fork is `0x01` but this is too weak for reliable
detection on its own.

## Structure

The format is not publicly documented. Known details from reverse
engineering:

| Offset | Size | Field |
|--------|------|-------|
| 0      | 1    | Format marker (0x01) |
| 1      | 1    | Volume byte |
| ...    | var  | Header data |

The internal structure includes a file/directory tree with per-entry
compression, preserving the full Mac filesystem metadata.

## History

- ~1990: Compact Pro released as shareware
- 1990s: Widely used alongside StuffIt for Mac file distribution
- 2002: Development ceased, StuffIt had won the Mac archive format war

## Current Status

- No maintained tools for extraction
- The Unarchiver (macOS) can extract .cpt files
- Format is effectively dead
- Mac type `PACT`, creator `CPCT`

## References

- [Archive Team: Compact Pro](http://justsolve.archiveteam.org/wiki/Compact_Pro)
