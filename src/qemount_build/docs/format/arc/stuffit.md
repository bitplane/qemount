---
title: StuffIt
created: 1987
discontinued: 2019
related:
  - format/arc/macbinary
  - format/arc/binhex
detect:
  any:
    - offset: 0
      type: string
      value: "SIT!"
    - offset: 0
      type: string
      value: "StuffIt"
---

# StuffIt

StuffIt was created by Raymond Lau in 1987 as a teenager's shareware
project. It became THE archive format for the Macintosh platform for
nearly two decades. Later developed by Aladdin Systems (renamed Smith
Micro Software). StuffIt X (.sitx) was introduced in 2002 as a
cross-platform successor.

## Characteristics

- Preserves Macintosh resource forks and Finder metadata
- Multiple compression methods evolved over versions
- Encryption support
- Self-extracting archive support
- Segment spanning
- StuffIt X added cross-platform support and better compression

## Detection

| Magic | Format |
|-------|--------|
| `SIT!` at offset 0 | StuffIt classic |
| `SITD` at offset 0 | StuffIt Deluxe |
| `StuffIt` at offset 0 | Newer StuffIt |
| `Seg` at offset 0 | StuffIt Deluxe Segment |

StuffIt X (.sitx) uses a different format but no distinct magic entry
exists in the `file` database.

## History

- 1987: Raymond Lau releases StuffIt 1.0 as shareware
- 1990: Aladdin Systems acquires rights
- 1993: StuffIt Deluxe with new compression
- 2002: StuffIt X introduced (.sitx, cross-platform)
- 2011: Smith Micro acquires from Allume (renamed Aladdin)
- 2019: Effectively discontinued

## File Extensions

| Extension | Format |
|-----------|--------|
| `.sit` | StuffIt classic |
| `.sitx` | StuffIt X |
| `.sea` | Self-extracting archive |

## References

- [The Unarchiver](https://theunarchiver.com/) — can extract StuffIt files
