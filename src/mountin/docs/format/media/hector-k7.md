---
title: Hector cassette (K7)
created: 1981
system: Micronique Hector / Victor (French Z80 home computer)
extensions: [".k7", ".for", ".cin"]
aliases:
  - Hector tape
  - Hector cassette
related:
  - format/disk/hector-disc2
  - format/disk/hector-minidisc
---

# Hector cassette (K7)

An audio-cassette program/data image for the Micronique Hector, the French
Z80 home computer that shipped with a built-in cassette recorder ("K7" is the
common French abbreviation for *cassette*). The Hector line descends from the
US Interact / Victor Lambda machine; Micronique sold it from 1981 and renamed it
"Hector" in 1983. See [Hector Disc2](../disk/hector-disc2) and
[Hector minidisc](../disk/hector-minidisc) for the system's floppy formats.

This is a **knowledge-only** entry: it is a modulated audio bitstream, not a
mountable filesystem, disk image, partition table or archive. There is nothing
to mount, so it is catalogued for identification and cross-reference and carries
no driver.

## Encoding

MAME renders/reads the tape as pulse-width-modulated audio (16-bit PCM at
44,100 Hz). The bitstream is built from timed cycles rather than fixed audio
frequencies:

- A long synchronisation leader (the loader uses 768 sync cycles ahead of the
  data)
- Data bytes sent 8 bits at a time, LSB first, each bit a high/low cycle whose
  width distinguishes 0 from 1 (the loader uses ~27 cycles for a 0 bit and ~50
  for a 1 bit, with ~77-cycle header sync cycles)
- Inter-block gaps of either a short run of cycles or a longer 150-cycle resync
  after a `0xFE` marker

Three extensions appear: `.k7` for ordinary cassette images, `.cin` as an
alternative cassette extension, and `.for` for Forth-language tapes (which MAME
treats as fixed 822-byte blocks each preceded by sync cycles). There is no
in-band magic signature; the format is recognised by extension and block
structure.

## References

- MAME loader: [`src/lib/formats/hect_tap.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/hect_tap.cpp)
- [Hector (microcomputer) — Wikipedia](https://en.wikipedia.org/wiki/Hector_(microcomputer))
- [Hector (micro-ordinateur) — Wikipédia (FR)](https://fr.wikipedia.org/wiki/Hector_(micro-ordinateur))
- [Micronique Hector — Emu-France](https://www.emu-france.com/emulateurs/10-ordinateurs/245-micronique-hector/)
