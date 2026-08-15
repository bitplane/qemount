---
title: VG5000 cassette (K7)
created: 1984
system: Philips VG5000 (VG5000µ), France
extensions: [".k7"]
aliases:
  - VG5000 K7
  - Philips VG-5000 tape
related:
  - format/media/hector-k7
  - format/media/thom-cas
  - format/media/coco-cas
---

# VG5000 cassette (K7)

A cassette-tape image for the Philips VG5000µ, an educational home computer
launched in France on 1 October 1984. The machine was built around a 4 MHz Zilog
Z80A, manufactured by Radiotechnique (RTS) in Le Mans, and sold under the
Philips, Radiola and Schneider brands. It used cassette tape as its primary
storage, with a 1200/2400-baud DIN cassette interface; `.k7` ("K7" being the
French phonetic spelling of "cassette") is the digital image of that tape.

This is a structured tape image rather than a mountable filesystem, so it is
catalogued here for identification and cross-reference only — there is no
on-media directory to mount.

## Structure

According to the MAME cassette converter, a `.k7` image is a sequence of blocks
that the loader renders to an audio waveform (44.1 kHz). A file is expected to
begin with a header (head) block:

- **Head block** — a 32-byte block led by a marker (`0xD3` repeated three times),
  preceded by about a second of silence and followed by a synchronisation run.
  It carries the name and the length of the data that follows.
- **Data block** — led by a different marker (`0xD6`), its length taken from the
  preceding head block (plus a small trailer), again surrounded by silence and a
  sync run.

Bits are encoded as cycles of a base sample period: a `1` as two short cycles and
a `0` as one long cycle, with an end-of-byte marker between bytes. The image ends
with a run of silence. These block markers come from the MAME loader; an
independent converter (Triceraprog's `vg5000_tools`) parses the same `.k7` block
structure back into BASIC listings, but this page does not assert a detection
signature on a single corroborated source.

## References

- MAME source: [`src/lib/formats/vg5k_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/vg5k_cas.cpp)
  — head block (`0xD3` marker, 32 bytes) and data block (`0xD6` marker), bit
  cell timing, silence/sync runs, 44.1 kHz output.
- [Philips VG5000 — Wikipedia](https://en.wikipedia.org/wiki/Philips_VG5000) —
  system background: France, 1984, Z80A at 4 MHz, cassette storage at 1200/2400
  baud.
- [Triceraprog/vg5000_tools — k7_to_bas.py](https://github.com/Triceraprog/vg5000_tools/blob/master/k7_to_bas.py)
  — independent tool that reads `.k7` cassette images.
