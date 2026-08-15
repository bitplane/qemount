---
title: NRG (Nero Burning ROM)
created: 1997
related:
  - format/fs/iso9660
  - format/disk/cdi
detect:
  any:
    # NER5 - new format with 64-bit offset at -12
    - offset: -12
      type: string
      value: "NER5"
    # NERO - old format with 32-bit offset at -8
    - offset: -8
      type: string
      value: "NERO"
---

# NRG (Nero Burning ROM)

Nero Burning ROM's native disc image format. Nero was one of the most popular
CD/DVD burning applications on Windows from the late 1990s through 2000s.

## Background

Nero AG (originally Ahead Software) released Nero Burning ROM in 1997. The NRG
format became widely used for disc images, though less common for piracy than
CDI due to Nero being commercial software. The format evolved from a simple
32-bit offset scheme (NERO) to a 64-bit version (NER5) for larger images.

## Format Versions

- **NERO** - Original format, 32-bit offsets (pre-5.5)
- **NER5** - Extended format, 64-bit offsets (Nero 5.5+)

## File Structure

```
+---------------------------+
| Track Data                |  Raw sector data
| (variable size)           |
+---------------------------+
| Chunk Stream              |  Metadata chunks
+---------------------------+
| Footer (8 or 12 bytes)    |  Signature + chunk offset
+---------------------------+
```

### Footer Structure

**NER5 format** (at filesize - 12):

| Offset | Size | Description |
|--------|------|-------------|
| 0 | 4 | Signature "NER5" |
| 4 | 8 | Chunk offset (big-endian 64-bit) |

**NERO format** (at filesize - 8):

| Offset | Size | Description |
|--------|------|-------------|
| 0 | 4 | Signature "NERO" |
| 4 | 4 | Chunk offset (big-endian 32-bit) |

## Chunk Types

All chunks have 4-byte ID + 4-byte big-endian length + payload.

| Chunk ID | Purpose |
|----------|---------|
| CUEX | Cue sheet (extended, DAO mode) |
| CUES | Cue sheet (old format) |
| DAOX | DAO track descriptor (extended) |
| DAOI | DAO track descriptor (old) |
| ETN2 | Track extent info (extended, TAO) |
| ETNF | Track extent info (old, TAO) |
| CDTX | CD-TEXT metadata |
| MTYP | Medium type |
| SINF | Session info |
| END! | Chunk stream terminator |

## Recording Modes

### DAO (Disc-At-Once)

Uses DAOX/DAOI chunks with CUEX/CUES:
- Defines pregap, track start, and end offsets
- Includes ISRC codes
- Mode codes determine sector type

### TAO (Track-At-Once)

Uses ETN2/ETNF chunks:
- Simpler format with offset, size, mode per track
- No separate cue points

## Mode Codes

| Code | Sector Type | Size |
|------|-------------|------|
| 0x00 | Mode 1 | 2048 |
| 0x02 | Mode 2 | 2336 |
| 0x03 | Mode 2 XA Form 1 | 2048 |
| 0x06 | Mode 2 Raw | 2352 |
| 0x07 | Audio | 2352 |
| 0x0F | Mode 1 Raw | 2352 |
| 0x10 | Mode 2 XA Form 1 Raw | 2352 |
| 0x11 | Mode 2 XA Form 2 Raw | 2352 |

## Detection

Footer-based detection:

1. Check for "NER5" at (filesize - 12)
2. If not found, check for "NERO" at (filesize - 8)
3. Read chunk offset (big-endian)
4. Parse chunk stream for track information

## References

- [libmirage NRG parser](https://github.com/cdemu/cdemu/tree/master/libmirage/images/image-nrg)
- [Nero AG](https://www.nero.com/)
