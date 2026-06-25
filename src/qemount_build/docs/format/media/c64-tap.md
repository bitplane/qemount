---
title: Commodore TAP (raw cassette)
created: unknown
system: Commodore 64 / VIC-20 / C16 / Plus-4
extensions: [".tap"]
aliases:
  - C64-TAPE-RAW
  - C16-TAPE-RAW
related:
  - format/media/c64-crt
---

# Commodore TAP (raw cassette)

A low-level capture of a Commodore Datassette tape, preserving the raw pulse
timings of the recorded signal rather than decoded files. Because it stores
pulse lengths directly, TAP faithfully reproduces turbo loaders and copy
protections that ordinary file-level formats lose. It covers the C64, VIC-20,
C16/Plus-4 family.

This is a **knowledge-only** entry: it is a raw tape pulse stream, not a disk
image, filesystem, partition table, or archive. There is nothing to mount; it is
catalogued for identification and cross-reference.

## Structure

A 20-byte header precedes the pulse data:

- `0x00`: 12-byte signature `C64-TAPE-RAW` (or `C16-TAPE-RAW` for the C16/Plus-4
  variant)
- `0x0C`: version (0, 1, or 2)
- `0x0D`: machine/platform byte (C64, VIC-20, C16)
- `0x0E`: video standard (PAL / NTSC)
- `0x10`: data length, little-endian
- `0x14`+: pulse data

Each pulse byte gives a duration of `8 × value` clock cycles. In **version 0** a
`0x00` byte just means "overflow" — a pulse longer than 255×8 cycles, with no
exact value recorded. In **versions 1 and 2** a `0x00` is followed by three
little-endian bytes giving the precise cycle count, so long pulses are preserved
exactly. The clock rate depends on the machine and video standard (for example
C64 PAL ≈ 985 kHz, giving the per-pulse timings emulators use to rebuild the
waveform).

## Detection

MAME's loader and the community TAP specifications agree the file begins with the
12-byte ASCII signature `C64-TAPE-RAW`, with `C16-TAPE-RAW` used for the
C16/Plus-4 variant.

## References

- MAME loader: [`src/lib/formats/cbm_tap.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/cbm_tap.cpp)
- [Raw Tape .TAP file format — computerbrains.com](http://www.computerbrains.com/tapformat.html)
- [TAP — C64-Wiki](https://www.c64-wiki.com/wiki/TAP)
- [TAP format — schepers/unusedino](http://unusedino.de/ec64/technical/formats/tap.html)
