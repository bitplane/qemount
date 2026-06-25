---
title: KIM-1 cassette
created: 1976
system: MOS/Commodore KIM-1 (6502)
extensions: [".kim"]
aliases:
  - KIM-1 tape
  - KIM cassette
---

# KIM-1 cassette

A cassette image for the MOS Technology KIM-1, the single-board 6502 trainer
introduced in 1976 (and continued by Commodore after it acquired MOS). This is a
**knowledge-only** entry: the data is a memory dump recorded as audio, with no
mountable filesystem, so it is catalogued for identification and cross-reference
rather than mounted. There is **no driver** for it.

## Tape encoding

The KIM-1 monitor ROM records a region of memory as a self-describing record. On
tape the record is a leader of 100 SYN bytes (`0x16`), a single start-of-record
mark `*` (`0x2A`), the one-byte record ID, the start address, then the data, an
end mark `/` (`0x2F`), and a two-byte checksum, finishing with two `0x04` (EOT)
bytes. Every byte of address, data and checksum is sent as two ASCII hex
characters (`0`–`9`, `A`–`F`), each nibble in turn, so the payload is human-
readable hex rather than raw binary. The bits themselves are frequency-shift
keyed, with the high tone around 3600 Hz and the low tone around 2400 Hz.

MAME reads a small container that wraps this payload, beginning with the four
ASCII bytes `KIM1`, followed by little-endian start-address and length fields and
a file-ID byte before the data, and re-synthesises the tape audio from it on
load.

## Detection

The MAME container is identified by its four-byte ASCII magic `KIM1` at offset 0.
The tape stream itself has no single magic byte but is recognised by its 100-byte
`0x16` SYN leader followed by the `0x2A` start mark — a structure confirmed by
both the KIM-1 user documentation and independent format references.

## References

- MAME loader: [`src/lib/formats/kim1_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/kim1_cas.cpp)
- [KIM-1 data cassette — Just Solve the File Format Problem](http://fileformats.archiveteam.org/wiki/KIM-1_data_cassette)
- [Recording programs with the KIM-1 — retro.hansotten.nl](http://retro.hansotten.nl/6502-sbc/kim-1-manuals-and-software/kim-1-articles/recording-programs-with-the-kim-1-and-the-cassette-recorder/)
- [KIM-1 — Wikipedia](https://en.wikipedia.org/wiki/KIM-1)
