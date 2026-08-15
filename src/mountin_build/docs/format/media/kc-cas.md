---
title: KC 85 / KC 87 cassette
created: 1984
system: Robotron KC 85 / KC 87 (East German Z80)
extensions: [".kcc", ".tap", ".tp2", ".kcm", ".sss"]
aliases:
  - KC-TAPE
  - KCC
  - Robotron KC cassette
related:
  - format/disk/kc85
---

# KC 85 / KC 87 cassette

A cassette image for the East German Robotron KC 85 and KC 87 (Z 9001) home
computers. This is a **knowledge-only** entry: the data is a program or BASIC
file stored as a series of tape blocks, with no mountable filesystem, so it is
catalogued for identification and cross-reference rather than mounted. There is
**no driver** for it.

## Structure

KC tape data is organised into fixed 128-byte blocks. On tape each block is
preceded by a run of sync cycles and a separator, then a one-byte block number
(the block ID), the 128 data bytes, and — in the checksummed variants — a
trailing checksum byte, giving a 130-byte block on disk. MAME re-synthesises the
audio as frequency-shift keying: a 0 bit is one cycle of 2400 Hz, a 1 bit one
cycle of 1200 Hz, and a 600 Hz tone serves as the per-byte separator, with a
long leader of 1-bits and a second of silence bracketing the recording.

The several extensions are the same block stream packaged differently:

| Extension | Contents |
|-----------|----------|
| `.kcc` | raw blocks, block number but no checksum |
| `.tap` | KC-Emulator format: a text header plus block ID per block |
| `.tp2` | blocks with ID and checksum (130-byte blocks) |
| `.kcm` | as `.tp2` but without the header |
| `.sss` | BASIC data, headerless (first 11 bytes omitted) |

## Detection

Two independent descriptions (MAME's loader and the KC emulator community) agree
that the `.tap` variant begins with the literal ASCII header `KC-TAPE by AF` (a
fixed 16-byte signature), which is how that variant is distinguished from the
headerless `.kcc`/`.kcm` block dumps. The other variants carry no fixed
signature.

## References

- MAME loader: [`src/lib/formats/kc_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/kc_cas.cpp)
- [Castool — MAME documentation (KC cassette formats)](https://docs.mamedev.org/tools/castool.html)
- [Robotron KC 85/3 — oldcomputer.info](http://oldcomputer.info/8bit/kc85_3/index.htm)
- [KC 85 — Wikipedia (128-byte tape blocks, 2400/1200/600 Hz FSK)](https://en.wikipedia.org/wiki/KC_85)
