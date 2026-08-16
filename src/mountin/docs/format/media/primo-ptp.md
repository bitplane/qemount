---
title: Primo PTP cassette image
created: 1984
system: Primo (Microkey / SZTAKI, Hungary)
extensions: [".ptp"]
aliases:
  - Primo tape program
  - primoptp
---

# Primo PTP cassette image

A tape image for the **Primo**, the first commercially sold Hungarian home
computer (1984), developed at SZTAKI and marketed under the Microkey name. The
Primo is a Z80-based 8-bit machine that shipped in 16, 32 and 48 KB RAM
versions and stored programs on ordinary audio cassettes. PTP stands for "Primo
Tape Program" and captures the logical byte stream of a Primo cassette rather
than a raw audio waveform (the companion `.wav` form holds the latter).

This is a **knowledge-only** entry. A PTP file is the serialised contents of a
program tape, not a mountable filesystem, disk image, partition table, or
archive, so there is nothing to mount. It is catalogued for identification and
cross-reference; no driver is planned.

## Structure

Per MAME's loader, a PTP file is a sequence of **file records**, and each file
is in turn a sequence of **blocks**:

- A file begins with a 3-byte file header; bytes 1-2 carry the file size as a
  little-endian 16-bit value (`size = b[1] + b[2] * 256`).
- Each block within a file begins with a 3-byte block header; bytes 1-2 carry
  the block size (little-endian 16-bit), counting the block payload and its
  trailing CRC but not the header itself.

When MAME synthesises audio from this it inserts a per-file pilot tone of 512
bytes of `0xAA` and a per-block pilot of 96 bytes of `0xFF` followed by three
`0xD3` sync bytes, at 22,050 Hz. These are playback parameters, not on-disk
magic, so there is no fixed signature at the start of the file and no Detection
section here.

## References

- MAME loader: [`src/lib/formats/primoptp.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/primoptp.cpp)
- [Primo home computer — Informatika Történeti Kiállítás](https://ajovomultja.hu/primo-home-computer?language=en)
- [Primo — 1000 BiT](https://www.1000bit.it/scheda.asp?id=1795)
- [PTP file extension — file-extensions.org](https://www.file-extensions.org/ptp-file-extension-primo-computer-emulator-tape-image)
- [vargaviktor/primotools — PTP/PRI converter](https://github.com/vargaviktor/primotools)
