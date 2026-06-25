---
title: Acorn Atom cassette (TAP)
created: 1980
system: Acorn Atom
extensions: [".tap"]
aliases:
  - Atom tape image
related:
  - format/disk/atom
---

# Acorn Atom cassette (TAP)

A cassette-tape image for the Acorn Atom (1980). The Atom stored programs on
ordinary audio cassette using a Kansas City Standard variant: bits are sent at
300 baud as 1200 Hz (logic 1) and 2400 Hz (logic 0) tones, each byte framed by
a start bit, eight data bits LSB-first, and two stop bits.

This is a **knowledge-only** entry. A `.tap` file is the decoded block stream of
a tape, not a mountable filesystem — there is no directory or partition table to
mount — so it is catalogued for identification and cross-reference, with no
driver planned. For the Atom's floppy format see `disk/atom`.

## Structure

The file is a sequence of named blocks. Each block carries:

- four sync bytes (`0x2A`)
- the filename, 1–13 characters
- a `0x0D` terminator
- a block flag byte (positioning / data-present bits)
- a 2-byte block number, high byte first
- a "data length minus one" byte
- a 2-byte execution address, high byte first
- a 2-byte load address, high byte first
- 0–256 bytes of data
- a 1-byte checksum (sum modulo 256 from filename through data)

A file is reassembled by concatenating the data fields of its consecutive
blocks in block-number order.

## References

- MAME loader: [`src/lib/formats/atom_tap.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/atom_tap.cpp)
- [Kansas City standard — Wikipedia](https://en.wikipedia.org/wiki/Kansas_City_standard)
- [Acorn Atom — Wikipedia](https://en.wikipedia.org/wiki/Acorn_Atom)
