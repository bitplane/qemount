---
title: EACA Colour Genie cassette
created: 1982
system: EACA Colour Genie EG2000
extensions: [".cas"]
aliases:
  - Colour Genie Virtual Tape File
  - Color Genie cassette
related:
  - format/disk/cgenie
  - format/media/coco-cas
---

# EACA Colour Genie cassette

A cassette-tape image for the EACA Colour Genie EG2000, a Z80-based colour home
computer made by EACA (Hong Kong) and sold from 1982. Programs were loaded from
ordinary audio cassettes; this `.cas` format captures the tape's byte stream so
emulators can replay it.

This is a **knowledge-only** entry: it is a serialised tape, not a mountable
filesystem, partition table, or archive. It is catalogued for identification and
cross-reference.

## Structure

MAME's loader recognises three layouts:

- a file beginning with the header string `Colour Genie - Virtual Tape File`
  followed by a NUL terminator;
- a file with 255 leading `0xAA` sync bytes and no header string;
- a bare file with neither.

After any header/sync is skipped, the body is the sequence of tape bytes, which
MAME modulates back into audio (each bit produces a boundary sample and a value
sample at a 2400 Hz rate). A tape-marker byte `0x66` is expected at the start of
the data proper. The MAME loader is noted as incomplete ("only the sync signal
and 0x66 byte get recognized"), so it serves more for identification than for
full playback.

## References

- MAME loader: [`src/lib/formats/cgen_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/cgen_cas.cpp)
- [Colour Genie — Wikipedia](https://en.wikipedia.org/wiki/Colour_Genie)
- [EACA Colour Genie — classic-computers.org.nz](https://www.classic-computers.org.nz/system-80/hardware_eaca-colour-genie.htm)
