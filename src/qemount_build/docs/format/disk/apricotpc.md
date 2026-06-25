---
title: Apricot PC/Xi floppy image
created: unknown
system: ACT Apricot PC / Xi (UK)
extensions: [".img"]
aliases:
  - Apricot PC disk
related:
  - format/disk/apridisk
  - format/disk/raw
---

# Apricot PC/Xi floppy image

A raw, headerless sector image for the 3.5" floppy drives of the ACT Apricot PC
and Apricot Xi, business microcomputers from Applied Computer Techniques (ACT) of
Birmingham, UK, launched in 1983–1984. The machines used a WD2797 floppy
controller; the on-disk layout is MFM and broadly compatible with the NEC uPD765
geometry conventions.

Early Apricots shipped with Sony 70-track single-sided drives (the 315 KB
format); later models used 80-track double-sided drives (the 720 KB format).
The image is a flat dump of sector data with no signature, decoded by MAME
through its `wd177x_format` base class.

## Geometry

| Capacity | Tracks | Sides | Sectors/track | Bytes/sector | Encoding |
|----------|--------|-------|---------------|--------------|----------|
| 315 KB | 70 | 1 | 9 | 512 | MFM (single-sided) |
| 720 KB | 80 | 2 | 9 | 512 | MFM (double-sided) |

The richer, self-describing Apricot disk container is the separate APRIDISK
format (see related).

## References

- MAME loader: [`src/lib/formats/apricotpc_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/apricotpc_dsk.cpp)
- [Apricot PC — Wikipedia](https://en.wikipedia.org/wiki/Apricot_PC)
- [ACT/Apricot disks — actapricot.org](https://actapricot.org/disks/aprid5ks.htm)
