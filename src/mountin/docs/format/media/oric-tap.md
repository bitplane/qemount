---
title: Oric cassette tape (TAP)
created: 1983
system: Oric (Oric-1 / Atmos / Telestrat)
extensions: [".tap"]
aliases:
  - Oric TAP
  - oric_tap
related:
  - format/disk/oric
  - format/fs/oric-jasmin
---

# Oric cassette tape (TAP)

Before (and alongside) floppy drives, the Oric-1 and Oric Atmos loaded software
from cassette using a ROM tape routine. The `.tap` format is the emulator
representation of that tape: a logical byte stream as the Oric ROM would read it,
which a loader expands into an audio waveform. It is the tape counterpart to the
[`disk/oric`](../disk/oric.md) MFM_DISK floppy image.

This is a **knowledge-only** entry: a cassette program stream, not a disk image,
filesystem, partition table, or archive. There is nothing to mount; it is
catalogued for identification and cross-reference, and marked no-driver.

## Structure

A recorded file is framed by a synchronisation lead-in and a fixed header. The
loader scans the stream for a run of `0x16` bytes terminated by a `0x24` sync
byte; in practice the ROM expects on the order of three or four `0x16` bytes
before the `0x24`. After the sync comes a short header carrying a type byte
(BASIC vs machine-code), an autostart flag, the program's end and start
addresses (each as a high/low byte pair), and a null-terminated filename, after
which the program data follows. Separator bits and additional `0x16` lead-in are
inserted between header and data.

At the waveform level MAME (whose loader notes credit Fabrice Frances's
`tap2wav`) clocks the bitstream at 4800 Hz, with each byte sent as a 13-bit
frame — a start bit, 8 data bits LSB-first, an even-parity bit, and four stop
bits — encoding a `0` bit as four cycles at 1200 Hz and a `1` bit as eight
cycles at 2400 Hz.

## Detection

MAME's loader and independent Oric tape documentation agree that a file/record
is introduced by a short run of `0x16` lead-in bytes immediately followed by a
single `0x24` sync byte (commonly written as the sequence `16 16 16 24`). This
marks a record boundary rather than acting as a fixed file-offset-0 magic, so it
is documented here for identification rather than as a strict signature.

## References

- MAME loader: [`src/lib/formats/oric_tap.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/oric_tap.cpp)
- [TAP (Oric) — Just Solve the File Format Problem](http://fileformats.archiveteam.org/wiki/TAP_(Oric))
- [Tape Header Format — Defence Force forum](https://forum.defence-force.org/viewtopic.php?t=201)
- [oricutron/tape.c — pete-gordon/oricutron (GitHub)](https://github.com/pete-gordon/oricutron/blob/master/tape.c)
