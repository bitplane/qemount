---
title: Vector-06C floppy disk image
created: unknown
system: Vector-06C (Soviet home computer, late 1980s)
extensions: [".fdd"]
aliases:
  - Vector-06C FDD
  - Vector06 disk
related:
  - format/disk/fdd
  - format/disk/raw
---

# Vector-06C floppy disk image

A raw, headerless floppy-disk image for the Vector-06C, an 8-bit home computer
(KR580VM80A, a Soviet i8080 clone) designed by Donat Temirazov and Alexander
Sokolov and mass-produced in the USSR from the late 1980s. The base machine
stored programs on cassette, but a common expansion added an NGMD 5.25-inch
floppy controller, and emulators load that drive's contents from `.fdd` images.

The format carries no header or magic: it is a flat MFM sector dump at fixed
geometry, so identification relies on size and context rather than a signature.
The MAME loader recognises two geometries, both double-sided, double/quad density
at 2000 RPM with 1024-byte sectors:

- 80 tracks x 2 heads x 5 sectors x 1024 bytes = 800 KB
- 82 tracks x 2 heads x 5 sectors x 1024 bytes (a slightly over-tracked variant)

The 800 KB figure matches the capacity quoted for the Vector-06C floppy
expansion in general references on the machine.

Note the `.fdd` extension collision: it is also used by the unrelated NEC PC-98
[Virtual98 FDD](fdd) format, which is a fully headered, per-sector-metadata
image. The two share only the file extension; a Vector-06C image is a raw dump
with no `VFD` signature.

## References

- MAME source: [`src/lib/formats/vector06_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/vector06_dsk.cpp)
  — two raw geometries (80 or 82 tracks, 2 heads, 5 sectors of 1024 bytes), MFM,
  no header.
- [Vector-06C — Wikipedia](https://en.wikipedia.org/wiki/Vector-06C) — machine
  background, Soviet origin, floppy expansion (5.25-inch, ~800 KB).
- [vector06cc — Getting Started (GitHub wiki)](https://github.com/svofski/vector06cc/wiki/GettingStarted)
  — confirms `.fdd` as the standard Vector-06C floppy image format used by
  emulators and FPGA cores.
