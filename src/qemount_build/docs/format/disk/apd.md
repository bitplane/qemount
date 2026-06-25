---
title: APD (Archimedes Protected Disk)
created: unknown
system: Acorn Archimedes
extensions: [".apd"]
aliases:
  - Archimedes Protected Disk Image
related:
  - format/disk/acorn
  - format/fs/adfs
  - format/arc/gzip
  - format/disk/raw
---

# APD (Archimedes Protected Disk)

A gzip-compressed, flux-level disk image for the Acorn Archimedes, designed to
preserve copy-protected disks that a plain sector image cannot. Rather than
sectors, it stores the raw bit lengths of each track at single, double and quad
density, which an emulator decodes back into the disk's flux.

## Structure

The file is gzip-compressed (`1F 8B`); the decompressed stream begins with the
identifier `APDX0001`. It then holds:

- a per-track metadata table — 12 bytes per track, three 32-bit fields giving
  the SD / DD / QD bit lengths
- variable-length track bitstream data, beginning at offset `0x7D0`
- up to ~160 tracks

## References

- MAME loader: [`src/lib/formats/apd_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/apd_dsk.cpp)
- [Acorn Archimedes — Wikipedia](https://en.wikipedia.org/wiki/Acorn_Archimedes)
