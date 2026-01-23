---
title: CDI (DiscJuggler)
created: 1998
related:
  - format/fs/iso9660
  - format/disk/nrg
detect:
  all:
    - any:
        - offset: -8
          type: le32
          value: 0x80000004
          name: version_v2
        - offset: -8
          type: le32
          value: 0x80000005
          name: version_v3
        - offset: -8
          type: le32
          value: 0x80000006
          name: version_v35
    - offset: -4
      type: le32
      op: ">"
      value: 0
      name: header_offset_nonzero
    - offset: -4
      type: le32
      op: "<"
      value: 0x40000000
      name: header_offset_reasonable
---

# CDI (DiscJuggler)

DiscJuggler CDI - the Dreamcast piracy format of choice!

## Background

DiscJuggler was a French CD/DVD copying tool from Padus Inc., popular in the
early 2000s for bypassing copy protection (SafeDisc, SecuROM, etc.). It was
basically the "I need to back up my games" era software.

Its native .CDI image format is by far the most common format used to image
self-booting Dreamcast CDs. Due to its support of multisession CD images,
which was unique in the late-1990s, Dreamcast gamers commonly used the
software to burn Sega Dreamcast games.

Last version: DiscJuggler 6.00.1400 (April 2006) - dead software.

## Format Versions

- **CDI v2.0** - Original format
- **CDI v3.0** - Added features
- **CDI v3.5** - Extended support (DiscJuggler 3.5+)
- **CDI v4.0** - Later versions (DiscJuggler 4.0+)

## File Structure

```
+---------------------------+
| Sector Data               |  All sectors from 00:00:00
| (800h-990h bytes/sector)  |  Sector size varies per track
+---------------------------+
| Session/Track Info Blocks |  Track headers with metadata
+---------------------------+
| Footer (8 bytes)          |  Version + header offset
+---------------------------+
```

### Footer Structure

Located at `(filesize - 8)`:

| Offset | Size | Description |
|--------|------|-------------|
| 0 | 4 | Version (little-endian) |
| 4 | 4 | Header offset (little-endian) |

### Version Constants

| Value | Version |
|-------|---------|
| 0x80000004 | CDI v2.0 |
| 0x80000005 | CDI v3.0 |
| 0x80000006 | CDI v3.5 |

### Track Header Pattern

Track and disc headers contain: `FF FF 00 00 01 00 00 00 FF FF FF FF`

### Medium Type

Located at track/disc header offset 0x2E+F:
- `0x0098` = CD-ROM
- `0x0038` = DVD-ROM

## Detection

No magic bytes at offset 0. Detection via footer:

1. Seek to `(filesize - 8)`
2. Read 4-byte little-endian version
3. Check if version is 0x80000004, 0x80000005, or 0x80000006

Note: libmagic does not have detection rules for CDI.

## Track Structure

Each track contains:
- **mode**: Audio (0), Mode1 (1), or Mode2 (2)
- **sector_size**: 2048-2352 bytes
- **pregap_length**: Pre-gap sectors
- **length**: Track data length
- **start_lba**: Logical block address

## References

- [PSXSPX CDI Documentation](https://problemkaputt.de/psxspx-cdrom-disk-images-cdi-discjuggler.htm)
- [cdirip on GitHub](https://github.com/jozip/cdirip) - Reference parser implementation
- [Dreamcast Wiki - DiscJuggler](https://dreamcast.wiki/DiscJuggler)
- [DiscJuggler - Wikipedia](https://en.wikipedia.org/wiki/DiscJuggler)
