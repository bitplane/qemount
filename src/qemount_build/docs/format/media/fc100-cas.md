---
title: Goldstar FC-100 cassette image
created: unknown
system: Goldstar FC-100
extensions: [".cas"]
aliases:
  - fc100_cas
  - FC-100 tape image
---

# Goldstar FC-100 cassette image

A cassette-tape image for the Goldstar FC-100, an 8-bit Z80 home computer sold by
Goldstar (now LG) for the Korean market in the early 1980s. The FC-100 was built
around the same NEC PC-6001 lineage of hardware (Z80-compatible CPU, MC6847-class
video, AY-3-8910 sound) rather than the MSX standard. The `.cas` file holds the
logical byte stream of a program loaded from cassette.

This is a tape image with no filesystem to mount — it is catalogued here for
identification and cross-reference (no driver).

## Structure

MAME treats the `.cas` file as the program's data bytes and synthesises a tape
waveform from them at a 9600 Hz sample rate. Each byte is framed as one start bit
(0), eight data bits sent least-significant-bit first, and four stop bits (1).
A binary 1 is encoded as a short cycle (a pattern of low/high sample groups) and
a binary 0 as a longer cycle of twice the length. The synthesised stream begins
with a long run of "1" sync bits, then a 16-byte header, a further run of pause
bits, and finally the remaining data.

The MAME loader explicitly states that the real cassette frequencies are unknown
and that its encoding is a guess, so the timing details above describe MAME's
reconstruction rather than a verified hardware specification. The identity of the
FC-100 as a Goldstar Z80 home computer is independently corroborated, but the
byte-level `.cas` layout is documented from the MAME source only, so no detection
rule is asserted.

## References

- MAME source: [`src/lib/formats/fc100_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/fc100_cas.cpp)
  — synthesises a 9600 Hz tape waveform; the header comment notes the cassette
  frequencies are unknown and "it's all a guess."
- [Goldstar FC-100 — Generation MSX hardware database](https://www.generation-msx.nl/hardware/goldstar/fc-100/199/)
- [retro-1000/fc-100 — Goldstar 8-bit computer for the Korean market (GitHub)](https://github.com/retro-1000/fc-100)
- [NEC PC-6001 — Wikipedia (the architecture the FC-100 derives from)](https://en.wikipedia.org/wiki/PC-6000_series)
