---
title: PMD 85 Cassette Image (PMD / PTP)
created: 1985
system: Tesla PMD 85 (Czechoslovak)
extensions: [".pmd", ".tap", ".ptp"]
aliases: [PMD tape, PTP, PMD 85 tape package, pmd_cas]
related:
  - format/disk/iq151
---

These are cassette-tape images for the Tesla PMD 85, an 8-bit Czechoslovak
educational microcomputer built from 1985 around the MHB8080A (an Intel 8080
clone) by Tesla Piešťany. PMD 85 machines were deployed widely in Slovak schools,
filling the role the IQ 151 played in the Czech lands. Software was usually
distributed on cassette, and MAME's loader reads two related container styles.

This is a tape image with no filesystem to mount — it is catalogued here for
identification and cross-reference (no driver).

## Structure

MAME recognises two layouts:

- **PMD** — a raw tape capture. A block counts as a header when its first 48
  bytes form three sixteen-byte runs: sixteen `0xFF` bytes, then sixteen `0x00`
  bytes, then sixteen `0x55` bytes; the header region spans 63 bytes before the
  data follows.
- **PTP** — a "PMD 85 tape package": a sequence of blocks, each prefixed by a
  2-byte little-endian length, with pause gaps inserted between blocks (header
  blocks getting a longer pause).

When generating audio, MAME frames each byte as 1 start bit, 8 data bits and 2
stop bits (11 bits total), encoding each bit across six samples (half at one
level, half inverted) at a 7200 Hz sample rate with a 1200 Hz bit clock.

(The `0xFF`/`0x00`/`0x55` header pattern and the PTP block framing are described
from the MAME loader only; independent sources confirm the PMD 85's existence and
its PTP cassette format but were not cross-checked at the byte level, so no formal
detection rule is asserted here.)

## References

- MAME source: `src/lib/formats/pmd_cas.cpp`
  (https://github.com/mamedev/mame/blob/master/src/lib/formats/pmd_cas.cpp)
- PMD 85, Wikipedia:
  https://en.wikipedia.org/wiki/PMD_85
- Tesla PMD 85 8-bit computer, boginjr.com:
  https://boginjr.com/electronics/old/tesla-pmd85/
