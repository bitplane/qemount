---
title: CDDA (CD Digital Audio)
created: 1980
related:
  - format/disk/cdi
  - format/disk/nrg
  - format/fs/iso9660
---

# CDDA (CD Digital Audio)

Red Book audio - the original CD audio format standardized by Sony and Philips
in 1980. This is the format used for audio tracks on music CDs and mixed-mode
discs.

## Characteristics

- **Sample rate**: 44,100 Hz
- **Bit depth**: 16-bit signed
- **Channels**: 2 (stereo)
- **Byte order**: Little-endian
- **Sector size**: 2352 bytes (588 stereo samples)

## Data Layout

Each sector contains:
- 588 samples per channel
- 4 bytes per sample frame (2 bytes left + 2 bytes right)
- 2352 bytes total

```
+--------+--------+--------+--------+
| L0 L   | L0 H   | R0 L   | R0 H   |  Sample 0
+--------+--------+--------+--------+
| L1 L   | L1 H   | R1 L   | R1 H   |  Sample 1
+--------+--------+--------+--------+
|  ...   |  ...   |  ...   |  ...   |  ...
+--------+--------+--------+--------+
| L587 L | L587 H | R587 L | R587 H |  Sample 587
+--------+--------+--------+--------+
```

## Playing Time

- 1 sector = 1/75 second (75 sectors per second)
- 1 minute = 4500 sectors = 10,584,000 bytes
- 74 minutes (max CD) = 333,000 sectors = ~783 MB

## Detection

CDDA cannot be detected from raw bytes alone - it's just PCM samples with no
magic bytes or structure. Detection is only possible from container metadata:

- **CDI**: Track mode = 0 (Audio)
- **NRG**: Mode code = 0x07
- **CUE/BIN**: TRACK xx AUDIO
- **TOC**: TRACK AUDIO

## Subchannel Data

Full "raw" audio sectors include 96 bytes of subchannel data after the 2352
audio bytes, for a total of 2448 bytes:

- **P**: Pause flag
- **Q**: Track/index/time information (most important)
- **R-W**: CD-G graphics, CD-TEXT, or unused

## Related Formats

| Format | Description |
|--------|-------------|
| CD-TEXT | Artist/title metadata in subchannel |
| CD+G | Graphics in subchannel (karaoke) |
| HDCD | 20-bit audio encoded in 16-bit |

## References

- [Red Book (CD-DA) - Wikipedia](https://en.wikipedia.org/wiki/Compact_Disc_Digital_Audio)
- [ECMA-130](https://www.ecma-international.org/publications-and-standards/standards/ecma-130/)
