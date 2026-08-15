---
title: Sharp MZ tape image (MZF/MZT)
created: unknown
system: Sharp MZ series (MZ-80K/700/800/2000)
extensions: [".mzf", ".mzt", ".m12"]
aliases: [MZF, MZT, MZ cassette, Sharp MZ tape]
related:
  - format/disk/d88
  - format/disk/2d
---

# Sharp MZ tape image (MZF/MZT)

A cassette-tape image for Sharp's MZ-series 8-bit computers (MZ-80K/A, MZ-700,
MZ-800, MZ-80B/2000), which were "clean computer" designs that loaded their
language and OS from tape at boot. Rather than storing raw audio, the file
stores the logical tape contents: a fixed 128-byte header block describing the
file, followed by the program/data block, mirroring the two-part layout a real
MZ cassette uses.

This is a tape image with no filesystem to mount — it is catalogued here for
identification and cross-reference (no driver).

## Structure

Each logical file is a 128-byte header followed by its data. The header records,
among other fields, a file-type/mode byte (giving values such as machine-code,
BASIC text or BASIC data), a filename, the byte length of the data block, the
load address and the execution address. On the physical tape — which MAME
reconstructs as audio — the layout is a long gap, a long tape-mark sync pattern,
the header block with its checksum, a short gap, a short tape-mark, then the data
block with its checksum, encoded as pulse-width-modulated tones (short pulses for
0, long pulses for 1). The MZ-700/80A/800 family records at roughly 1200 baud
and the MZ-80B/2000 family at roughly 1800 baud.

An `.mzf` (also `.m12`) file holds a single header-plus-data file, while `.mzt`
is a tape image that may concatenate several such files one after another, as
they would sit on a physical tape.

## References

- MAME loader: [`src/lib/formats/mz_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/mz_cas.cpp)
  (`.m12`/`.mzf`/`.mzt`; 128-byte header block, header/data checksums, PWM
  encoding at 1200/1800 baud)
- [Difference between MZT and MZF files — sharpmz.org forum](https://forum.sharpmz.org/viewtopic.php?t=406) (MZF = one header + data block; MZT = concatenated tape image)
- [Displaying Sharp BASIC programs on modern computers — Tim Holyoake](https://z80.timholyoake.uk/displaying-sharp-basic-programs-on-modern-computers/) (128-byte header: file-type byte, file length, load address)
