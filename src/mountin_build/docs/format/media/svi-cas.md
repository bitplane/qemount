---
title: SVI cassette image
created: 1983
system: Spectravideo SVI-318 / SVI-328
extensions: [".cas"]
aliases:
  - Spectravideo cassette image
  - SVI-318/328 tape image
related:
  - format/disk/svi
---

# SVI cassette image

Cassette tape images for the Spectravideo SVI-318 and SVI-328, a pair of Zilog
Z80A home computers (3.58 MHz) launched in 1983. These machines predate and
strongly influenced the MSX standard; before the optional SVI-707 disk drive,
software was loaded from audio cassette, so the `.cas` tape image is the usual
distribution format.

This is a knowledge/identification entry only: the file is an encoded tape
bitstream, not a mountable filesystem, so there is no driver.

## Structure

A `.cas` image is a sequence of blocks. Each block begins with a fixed 17-byte
synchronisation header — sixteen `0x55` bytes followed by a single `0x7F` — and
then the block's data bytes; the same 17-byte sequence also separates one block
from the next. On replay the loader generates a 44.1 kHz waveform, using a
shorter bit period for a `1` and a longer one for a `0`, with a stretch of
silence inserted between blocks.

## Detection

Two independent sources (the MAME loader and community `.cas` tooling for the
SVI) agree that an SVI cassette block is introduced by the 17-byte marker of
sixteen `0x55` bytes followed by `0x7F`. A valid `.cas` file therefore opens
with this sequence, and it recurs as the block separator throughout the file.
Note this is a tape sync pattern, not a unique file signature, so it should be
treated as a strong hint rather than a guaranteed-unique magic.

## References

- MAME loader: [`src/lib/formats/svi_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/svi_cas.cpp)
- [SVI CAS — Spectravideo SV-318/328 SD-based tape loader (Retrounlim)](https://www.retrounlim.com/2020/07/05/svi-cas-spectravideo-sv-318-328-sd-based-tape-loader/)
- [Spectravideo SVI-318/328 — Video Games Museum](https://www.video-games-museum.com/en/sys/138-svi-318-328)
