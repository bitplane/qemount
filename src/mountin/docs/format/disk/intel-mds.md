---
title: Intel MDS-II floppy image
created: 1976
system: Intel Intellec MDS / Series II development systems
extensions: [".img"]
aliases:
  - Intel MDS img
  - Intellec floppy image
  - MDS-II disk image
related:
  - format/fs/isis
  - format/disk/imd
  - format/disk/raw
---

# Intel MDS-II floppy image

This `.img` format is a raw sector dump of the 8-inch floppies used by Intel's
Intellec Microprocessor Development System (the MDS / Series II machines) from
the mid/late 1970s. These are the same diskettes that carry the Intel ISIS-II
filesystem (see `format/fs/isis`); this entry covers the image-level sector
layout, while ISIS-II covers the on-disk directory structure.

The disks are single-sided, 8-inch, with 128-byte sectors across 77 cylinders,
in two density variants:

- **SSSD** (single-sided single-density): FM encoding, 26 sectors per track,
  yielding a 256,256-byte image. This is the IBM 3740 layout (~250 KB).
- **SSDD** (single-sided double-density): Intel's MMFM/M2FM encoding (which is
  *not* IBM System 34 / standard MFM compatible), 52 sectors per track, yielding
  a 512,512-byte image (~500 KB).

There is no header or magic; the format is a plain ordered sector dump and is
distinguished by total size and geometry. The MAME loader reconstructs full
track data (sector interleave, gaps and CRCs) for the appropriate density,
using a 1 µs MMFM bit cell or a 2 µs FM bit cell.

## References

- MAME loader: [`src/lib/formats/img_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/img_dsk.cpp)
- [Intel MDS-II System — nj7p.info](https://www.nj7p.info/Computers/Intel/MDS-II.html)
- [ISIS, Intellec, PL/M, iRMX and Intel — retrotechnology.com](http://www.retrotechnology.com/dri/isis.html)
- [ISIS (operating system) — Wikipedia](https://en.wikipedia.org/wiki/Intel_ISIS-II)
