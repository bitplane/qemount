---
title: SC-3000 .bit cassette image
created: unknown
system: Sega SC-3000 (Z80, 1983)
extensions: [".bit"]
aliases:
  - SC-3000 bit tape
related:
  - format/disk/sf7000
---

# SC-3000 .bit cassette image

A textual cassette image for the Sega SC-3000, the Z80-based home computer Sega
built around the SG-1000 console hardware in 1983. The `.bit` file is not raw
audio: it is an ASCII representation of the exact bitstream that was recorded on
(or should be played back to) the SC-3000's cassette interface, which writes
program data one bit at a time using a 1200/2400 Hz tone scheme.

This is a **knowledge-only** entry — a tape program image with a defined
character grammar, not a mountable filesystem. There is no driver.

## Structure

The file contains only three character values, each standing for one cassette
event lasting 1/1200 second (about 833 microseconds):

- `'0'` (0x30) — one full square-wave cycle at ~1200 Hz; a data bit of value 0.
- `'1'` (0x31) — two square-wave cycles at ~2400 Hz; a data bit of value 1.
- `' '` (0x20) — 1/1200 second of silence (a gap).

No other byte values are permitted. A player walks the file character by
character and synthesises the corresponding tone or silence, so the file is in
effect a human-readable transcript of the FSK tape waveform. There is no header
or magic signature; identification rests on the `.bit` extension and the fact
that the body is restricted to `0`, `1` and space. MAME modulates these into a
sinewave cassette waveform, accepting roughly 900-1500 Hz for a 0 and
1800-3000 Hz for a 1 on the way back in.

## References

- MAME loader: [`src/lib/formats/sc3000_bit.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/sc3000_bit.cpp)
  (parses `'0'`/`'1'`/`' '`, modulates as 1200/2400 Hz sinewave bits)
- [SC-3000 / SC-3000H Tape Restoration Project — sc3000-multicart.com](https://sc3000-multicart.com/sc3000-tape-restoration-project.htm)
  (`.bit` is one char per bit: space = 1/1200 s silence, `0` = one 1200 Hz cycle, `1` = two 2400 Hz cycles)
- [Sega SC-3000 — StickFreaks](https://stickfreaks.com/sega-sc-3000)
  (cassette data written bit-by-bit, ~833 us per bit)
