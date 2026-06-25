---
title: Juku disk image
created: 1988
system: Juku E5101 / E5104 (Estonian / Soviet school computer)
extensions: [".juk"]
aliases:
  - Juku E5101
  - Juku E5104
related:
  - format/disk/raw
  - format/fs/cpm
---

# Juku disk image

The Juku E5101 (and its 1988 follow-up the E5104) was a school microcomputer
designed in Soviet-era Estonia by the EKTA design bureau and the Institute of
Cybernetics of the Estonian Academy of Sciences, built around a KR580VM80A
(a Soviet Intel 8080A clone). It ran **EKDOS**, a localised CP/M 2.2
derivative, and the E5104 added dual 5.25-inch floppy drives.

`.juk` is the raw, fixed-geometry sector-dump image used for those floppies. It
is headerless — no magic or descriptor — and built on MAME's `wd177x_format`
base class, decoded for a Western Digital WD177x-class controller.

## Structure

The loader defines two double-density 5.25-inch geometries:

- 80 tracks, 10 sectors per track, 512 bytes per sector, MFM encoding
- single-sided (~400 KB) or double-sided (~800 KB)

The double-sided 80 × 2 × 10 × 512 layout gives the ~800 KB capacity reported
for the E5104's drives. The MAME source marks its gap parameters unverified, so
low-level timing is approximate. As a plain sector dump with no header there is
no content signature to match on, so no detection rule is documented here.

## References

- MAME loader: [`src/lib/formats/juku_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/juku_dsk.cpp)
- [Juku E5101 — Wikipedia](https://en.wikipedia.org/wiki/Juku_E5101)
- [Juku E5101/E5104 — MAME PR #9946 (working-machine status)](https://github.com/mamedev/mame/pull/9946/files)
