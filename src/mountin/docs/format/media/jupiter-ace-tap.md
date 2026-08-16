---
title: Jupiter Ace TAP (cassette image)
created: 1982
system: Jupiter Ace (Jupiter Cantab, UK)
extensions: [".tap"]
aliases:
  - Ace tape
---

# Jupiter Ace TAP (cassette image)

A structured cassette image for the Jupiter Ace, the 1982 Forth-based British
home computer from Jupiter Cantab (built by ex-Sinclair engineers). The `.tap`
file is not raw audio: it is a sequence of length-prefixed blocks that an
emulator (or MAME) modulates into the tape waveform on load.

This is a **knowledge-only** entry — a tape program image, not a mountable
filesystem.

## Structure

The file is a series of blocks, each preceded by a 16-bit little-endian length:

- A **header block** (length `0x001A` = 26 bytes) carrying the file type, name
  and load parameters — so the file begins with the bytes `1A 00`
- A **data block** with the program/dictionary payload

(Block layout per MAME's loader; `1A 00` is the header block's length field, not
a dedicated signature.)

## References

- MAME loader: [`src/lib/formats/ace_tap.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/ace_tap.cpp)
- [Jupiter Ace — Wikipedia](https://en.wikipedia.org/wiki/Jupiter_Ace)
