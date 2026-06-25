---
title: Orao cassette tape
created: 1984
system: Orao (Yugoslav/Croatian 6502 home computer)
extensions: [".tap"]
aliases:
  - Orao TAP
  - orao_cas
related:
  - format/media/galaksija-gtp
---

# Orao cassette tape

The Orao ("Eagle") was an 8-bit, 6502-based home/education computer designed by
Miroslav Kocijan for PEL Varaždin in 1984. It was adopted as a standard school
computer across parts of the former Yugoslavia (Croatia and Vojvodina) from the
mid-1980s into the early 1990s. Like most machines of its class, it loaded and
saved programs over a cassette interface, and this `.tap` format captures that
tape data for emulators.

This is a **knowledge-only** entry: a cassette program-load stream, not a disk
image, filesystem, partition table, or archive. There is nothing to mount; it is
catalogued for identification and cross-reference, and marked no-driver.

## Structure

MAME's loader recognises two variants:

- **Old format.** The file opens with the three bytes `0x68 0x01 0x00`, which
  MAME treats as the signature of the older layout. When present, it is followed
  by a fixed 360-byte header; the bitstream proper begins after it. Within each
  byte the bits are read in 0-to-7 order.
- **New format.** Files without that leading signature are treated as the newer
  layout: the data follows immediately with no header, and the bits of each byte
  are read in reverse (7-to-0) order.

In both cases the body is a bit-serial program image rather than a framed file
table: MAME walks it bit by bit and synthesises an audio waveform, encoding a
`0` bit as a short low/high pulse pair and a `1` bit as a longer pair, at a
44.1 kHz sample rate. The two-variant split and the `0x68 0x01 0x00` marker come
from MAME's reader; an independent byte-level specification of the `.tap`
container was not located, so the marker is not promoted to a detection rule
here. The Orao system itself, its 1984 origin and 6502 architecture, are well
documented independently.

## References

- MAME loader: [`src/lib/formats/orao_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/orao_cas.cpp)
- [Orao (computer) — Wikipedia](https://en.wikipedia.org/wiki/Orao_(computer))
- [Orao emulator — DeltaSoft](http://www.deltasoft.com.hr/projects/oraoemu.php)
- [mejs/orao — ROMs, programs and tools for the Orao (GitHub)](https://github.com/mejs/orao)
