---
title: CSW (Compressed Square Wave)
created: 2002
system: BBC Micro / ZX Spectrum and other cassette-based micros
extensions: [".csw"]
aliases:
  - Compressed Square Wave
related:
  - format/media/tzx
---

# CSW (Compressed Square Wave)

CSW ("Compressed Square Wave") is a cassette-tape capture format that stores the
sampled square-wave signal of a tape as a stream of pulse lengths rather than as
raw audio. It is a sample-rate-independent representation of the on/off
transitions a tape recorder produces, used by emulators of cassette-based micros
(BBC Micro, Acorn machines, ZX Spectrum and others) to preserve loadable tapes
compactly.

This is a **knowledge-only** media entry: it encodes a tape signal, not a
mountable filesystem, partition table, or archive. It is catalogued for
identification and cross-reference; no driver is planned.

## Structure

The file is a header followed by a compressed list of pulse durations. Per the
MAME loader and the published specification, the CSW-2 header is:

| Offset | Size | Field |
|--------|------|-------|
| 0x00 | 22 | Signature `Compressed Square Wave` |
| 0x16 | 1 | Terminator `0x1A` |
| 0x17 | 1 | Major version |
| 0x18 | 1 | Minor version |
| 0x19 | 4 | Sample rate |
| 0x1D | 4 | Total pulse count (after decompression) |
| 0x21 | 1 | Compression type (1 = RLE, 2 = Z-RLE / zlib) |
| 0x22 | 1 | Flags (bit 0 = initial polarity) |
| 0x23 | 1 | Header extension length |

All multi-byte values are little-endian. Pulses are run-length encoded; CSW v2
additionally allows the pulse stream to be deflated with zlib (Z-RLE). The
initial-polarity flag selects whether the signal starts at logical high or low.
(CSW v1 uses a similar but simpler header.)

## Detection

Independent sources agree that a CSW file begins with the 22-byte ASCII string
`Compressed Square Wave` immediately followed by the byte `0x1A`.

## References

- MAME loader: [`src/lib/formats/csw_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/csw_cas.cpp)
- [CSW technical specifications — RAMSoft](http://ramsoft.bbk.org.omegahg.com/csw.html)
- [Castool — MAME documentation](https://docs.mamedev.org/tools/castool.html)
