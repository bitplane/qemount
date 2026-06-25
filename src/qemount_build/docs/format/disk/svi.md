---
title: Spectravideo SVI disk image
created: 1983
system: Spectravideo SVI-318 / SVI-328 (SVI-707 / SVI-806 drive, CP/M)
extensions: [".dsk"]
aliases:
  - SVI-328 disk image
  - SVI-707 disk image
related:
  - format/media/svi-cas
  - format/disk/bw12
  - format/disk/kaypro
  - format/fs/cpm
  - format/disk/raw
---

# Spectravideo SVI disk image

A raw, headerless sector image for the Spectravideo SVI-318/328 fitted with the
SVI-707 (or later SVI-806) 5.25-inch floppy drive. The SVI-707 ran CP/M and
could also read disks formatted for several other CP/M machines, but this image
format describes the SVI's own native disk layout.

The distinctive feature is a mixed-density boot track. Track 0 of head 0 holds
18 sectors of 128 bytes recorded in FM (single density), while every other
track holds 17 sectors of 256 bytes recorded in MFM (double density). That gives
the two standard image sizes:

| Geometry | Tracks | Heads | Capacity |
|----------|--------|-------|----------|
| Single-sided | 40 | 1 | 172,032 bytes (~168 KB) |
| Double-sided | 40 | 2 | 346,112 bytes (~338 KB) |

There is no container header or magic in the file; like other CP/M-era sector
dumps it is decoded straight through a WD-FDC / uPD765-style track model, and
the variant is selected purely by matching the file length against the two
sizes above.

The related [`disk/bw12`](bw12.md) loader reuses one set of geometries to cover
several CP/M 5.25-inch machines (Bondwell, Kaypro II) and lists the SVI-328's
plain 17×256 MFM tracks among them; this dedicated SVI loader additionally
models the FM 18×128 boot track that the native SVI format actually uses.

This is a headerless, fixed-geometry image, so there is no signature to match.

## References

- MAME loader: [`src/lib/formats/svi_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/svi_dsk.cpp)
- [Spectravideo SVI-707 — MSX Wiki](https://www.msx.org/wiki/Spectravideo_SVI-707)
- [SVI-707 floppy disk images / CP/M utilities — MSX Resource Center](https://www.msx.org/forum/msx-talk/general-discussion/svi-707-floppy-disk-images-andor-cpm-utilites)
- [spectravideo-floppy-emulator — kernelcrash (GitHub)](https://github.com/kernelcrash/spectravideo-floppy-emulator)
