---
title: Galaksija GTP tape image
created: unknown
system: Galaksija (Z80, Yugoslavia, 1983)
extensions: [".gtp"]
aliases:
  - GTP
  - Galaksija tape format
---

# Galaksija GTP tape image

A structured cassette image for the Galaksija, the Z80A-based home computer
designed in 1983 by Voja Antonić in Belgrade and built across Yugoslavia largely
from kits and magazine plans. The `.gtp` file is not raw audio: it is a sequence
of typed, length-prefixed blocks that an emulator (or MAME) modulates into the
Galaksija's FSK tape waveform on load.

This is a **knowledge-only** entry — a tape program image, not a mountable
filesystem.

## Structure

The file is a series of blocks, each beginning with a small header:

- a 1-byte **block type**,
- a 2-byte little-endian **block length**, and
- that many bytes of block data.

MAME recognises three block types: `0x00` (a normal data block, the one it
modulates), `0x01` (a "turbo" / fast-loader block) and `0x10` (a name block).
On replay each block is preceded by a synchronisation run and bytes are written
using frequency-shift keying, with short pauses between bytes and a long pause
between blocks. There is no fixed magic signature at the start of the file; the
first bytes are simply the first block's type and length.

The format is the native virtual-tape container for Galaksija emulation. It is
documented chiefly through the community tooling around it — Tomaž Šolc's
`gtp2wav` (which renders a `.gtp` to audio for a real machine) and `bin2gtp` /
`dump2gtp` (which build `.gtp` files) — rather than a formal published spec.

## References

- MAME source: [`src/lib/formats/gtp_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/gtp_cas.cpp)
  — block header is type byte + 2-byte LE length; types `0x00` data,
  `0x01` turbo, `0x10` name; replayed as FSK at 44.1 kHz.
- [Galaksija tooling and GTP notes — z88dk platform:galaksija](https://www.z88dk.org/wiki/doku.php?id=platform:galaksija)
- [mejs/galaksija — ROMs, programs and tools](https://github.com/mejs/galaksija)
- [Galaksija — oldcomputer.info](https://oldcomputer.info/8bit/galaksija/index.htm)
