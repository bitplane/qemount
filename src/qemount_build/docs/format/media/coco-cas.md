---
title: TRS-80 Color Computer cassette (CAS)
created: 1980
system: Tandy/Radio Shack TRS-80 Color Computer (CoCo)
extensions: [".cas", ".c10", ".k7"]
aliases:
  - CoCo cassette
  - Dragon cassette
related:
  - format/media/cgenie-tape
---

# TRS-80 Color Computer cassette (CAS)

A cassette-tape image for the Tandy/Radio Shack TRS-80 Color Computer (the
"CoCo", launched 1980) and compatibles such as the Dragon and the Matra/Hachette
Alice 32. Rather than sampled audio, a CAS file stores the **logical bytes** the
machine's BIOS read from or wrote to tape — "a legacy of previous CoCo
emulators" where the bits in the file are what the ROM saw, not modulated pulses.

This is a **knowledge-only** entry: although the byte stream is block-structured
and navigable, it is a serialised tape, not a mountable filesystem. It is
catalogued for identification and cross-reference.

## Structure

Tape data is organised as a sync leader followed by back-to-back blocks:

- a leader of at least 128 (often 255) repeated `0x55` sync bytes;
- each block starts with a `0x55` and a `0x3C` block marker, then:
  - a block-type byte — `0x00` file header, `0x01` data, `0xFF` end-of-file;
  - a length byte (`0x00`–`0xFF`); file headers are length 15, EOF blocks
    length 0;
  - the data payload (up to 255 bytes);
  - a checksum byte.

MAME decodes blocks one at a time until it hits the end of the file or a corrupt
block, which lets it recover the good blocks from legacy or copy-protected dumps.

## Detection

Two independent sources agree on the framing: blocks are introduced by the
sync byte `0x55` and the block marker `0x3C`, with the block-type byte
distinguishing header (`0x00`), data (`0x01`), and end-of-file (`0xFF`).

## References

- MAME loader: [`src/lib/formats/coco_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/coco_cas.cpp)
- [TRS-80 Color Computer — Wikipedia](https://en.wikipedia.org/wiki/TRS-80_Color_Computer)
- [Cross-platform development for the CoCo and Dragon — Bumbershoot Software](https://bumbershootsoft.wordpress.com/2024/02/17/cross-platform-development-for-the-trs-80-coco-and-dragon/)
