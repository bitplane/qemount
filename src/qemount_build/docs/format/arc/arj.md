---
title: ARJ
created: 1991
discontinued: 2007
detect:
  - offset: 0
    type: le16
    value: 0xea60
---

# ARJ (Archived by Robert Jung)

ARJ was created by Robert K. Jung in 1991 and became one of the most
popular DOS archive formats during the BBS era. It offered good compression
ratios and features like multi-volume spanning and self-extracting archives.

## Characteristics

- Multiple compression methods (stored, LZH variants)
- Multi-volume archives
- Self-extracting (SFX) support
- Password protection
- Path and attribute preservation
- Archive comments
- Error recovery records

## Structure

```
Archive header:
  Offset  Size  Field
  0       2     Magic (0xEA60 LE, bytes 60 EA)
  2       2     Basic header size
  4       1     First header size
  5       1     Archiver version needed
  6       1     Minimum version to extract
  7       1     Host OS
  8       1     ARJ flags
  9       1     Compression method
  10      1     File type
  ...
```

Each member file has a local header (also starting with 0xEA60) followed
by compressed data.

## Compression Methods

| ID | Method |
|----|--------|
| 0  | Stored |
| 1  | Most compressed |
| 2  | Less compressed |
| 3  | Less compressed |
| 4  | Fastest |

## History

- 1991: ARJ 1.0 released
- 1990s: Widely used on BBS systems alongside ZIP and RAR
- 1999: ARJ32 (32-bit version)
- 2007: Last known update

## References

- [ARJ Software](http://www.arjsoftware.com/)
