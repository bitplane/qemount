---
title: Atari 2600 SuperCharger cassette
created: 1982
system: Atari 2600 (Starpath/Arcadia SuperCharger)
extensions: [".a26"]
aliases:
  - Starpath cassette
  - Arcadia cassette
related:
  - format/media/cdda
---

# Atari 2600 SuperCharger cassette

A program encoded as modulated audio for loading into the Starpath (later
Arcadia) SuperCharger, a 1982 Atari 2600 peripheral. The SuperCharger held 6 KB
of SRAM and a 2 KB ROM bootloader; games shipped on ordinary audio cassettes and
were loaded by plugging the cassette player's earphone jack into the cartridge
and pressing play.

This is a **knowledge-only** entry: it is an audio/tape encoding of a single
program, not a disk image, filesystem, partition table, or archive — there is
nothing to mount. It is catalogued for cross-reference and identification.

## Characteristics

- Game data modulated as audio for playback through the SuperCharger
- 6 KB SRAM game image loaded via the 2 KB ROM bootloader
- Multi-load games are split across several tape segments

## Structure

The 8,448-byte load image has navigable internal structure (per MAME's loader):

- `0x0000`–`0x1FFF` — 8 KB game-data region, divided into 256-byte pages
- `0x2000` — 8-byte load header; the byte at `0x2003` holds the page count
- `0x2010`+ and `0x2040`+ — per-page control bytes describing how each page maps
  into the SuperCharger's RAM banks

There is no signature; MAME recognises the format by its exact 8,448-byte size.

## References

- MAME loader: [`src/lib/formats/a26_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/a26_cas.cpp)
- [Starpath Supercharger — Wikipedia](https://en.wikipedia.org/wiki/Starpath_Supercharger)
- [Arcadia/Starpath Supercharger — Nerdly Pleasures](http://nerdlypleasures.blogspot.com/2014/06/arcadiastarpath-supercharger-cassette.html)
