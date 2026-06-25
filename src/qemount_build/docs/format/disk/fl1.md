---
title: FL1 (FloppyOne DOS image)
created: 1984
system: ZX Spectrum (FloppyOne DOS Interface)
extensions: [".fl1"]
aliases:
  - FloppyOne
  - FloppyOne DOS
related:
  - format/disk/scl
  - format/disk/raw
---

# FL1 (FloppyOne DOS image)

FL1 is the disk-image format of the **FloppyOne DOS Interface**, a ZX Spectrum
floppy and printer interface. Per MAME's own device driver
(`src/devices/bus/spectrum/floppyone.cpp`), the FloppyOne was produced around
1984/85 by Rocky P. Gush in South Africa: an FD1791-based controller with 4 KB
RAM and 8 KB ROM, designed largely as a tape replacement so that unprotected
cassette software could run from disk with little or no modification (each side
of a drive is presented as a separate logical disk, echoing a tape's A/B sides).

The image is a plain, headerless sector dump decoded through MAME's WD177x MFM
layout. The loader recognises four fixed geometries, all using 1024-byte sectors,
5 sectors per track, 80 tracks, MFM:

- 5.25" 800 KB — double-sided, double density (DSQD)
- 5.25" 400 KB — single-sided, double density (SSQD)
- 3.5" 800 KB — double-sided, double density (DSDD)
- 3.5" 400 KB — single-sided, double density (SSDD)

Image offsets are linear: `((tracks * head) + track) * track_size`. There is no
magic signature, so the format is identified by extension and geometry/size
rather than by content.

Note: the FloppyOne is an obscure regional peripheral. The structural details
above (geometry, controller, MFM layout) come from MAME's loader and are
verifiable from the file structure, but the historical attribution (maker, year,
country) rests on MAME's device source and is not independently corroborated by
other public sources at the time of writing.

## References

- MAME format source: `src/lib/formats/fl1_dsk.cpp`
  (https://github.com/mamedev/mame/blob/master/src/lib/formats/fl1_dsk.cpp)
- MAME device driver (provenance): `src/devices/bus/spectrum/floppyone.cpp`
  (https://github.com/mamedev/mame/blob/master/src/devices/bus/spectrum/floppyone.cpp)
- Context on ZX Spectrum disk interfaces (e.g. Beta Disk, DISCiPLE) for the
  ecosystem this peripheral belongs to:
  https://en.wikipedia.org/wiki/Beta_Disk_Interface
