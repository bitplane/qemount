---
title: VGI disk image (Micropolis)
created: unknown
system: Micropolis MOD-I / MOD-II 5.25-inch floppy drives (S-100 era)
extensions: [".vgi"]
aliases:
  - Micropolis VGI
  - Micropolis hard-sector image
related:
  - format/disk/imd
  - format/disk/raw
---

# VGI disk image (Micropolis)

VGI is a raw disk image for Micropolis 5.25-inch hard-sectored floppy drives, as
used on S-100 systems of the late 1970s and early 1980s (Micropolis MetaFloppy
drives and the machines built around them, such as Vector Graphic systems). It
captures the disk exactly as the Micropolis controller saw it: a flat,
head/cylinder/sector-ordered dump, but with the **full 275-byte physical sector**
rather than only the user payload.

The 275 bytes preserve the on-disk sector framing that a plain user-data image
would discard. Per the MAME loader, each hard sector is laid out as a sync byte
(0xFF), a track byte, a sector byte, a 10-byte OS-reserved field, 256 bytes of
user data, a checksum byte, and a 4-byte ECC field plus an ECC-present flag. The
extra framing is exactly why the image is kept raw — it round-trips through the
real controller's sector model.

## Structure

There is no file header or magic; the format is identified by extension and by
its characteristic geometry. The MAME loader supports the two Micropolis drive
families:

- **MOD-I** — 35 tracks, 1 head (or 2 for double-sided), 16 hard sectors/track,
  275 bytes/sector (48 TPI).
- **MOD-II** — 77 tracks, 1 head (or 2 for double-sided), 16 hard sectors/track,
  275 bytes/sector (100 TPI).

With 256 user bytes in each of 16 sectors per track, MOD-II stores roughly 315 KB
per side. Because there is no header, do not rely on exact-size matching alone;
the 275-byte sector size is the format's distinguishing trait.

## References

- MAME source: [`src/lib/formats/vgi_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/vgi_dsk.cpp)
  — "HCS-ordered sector image" with raw 275-byte sectors; MOD-I/MOD-II
  geometries; per-sector sync/track/sector/OS-field/data/checksum/ECC layout.
- [Micropolis hard-sector disks — FluxEngine documentation](https://github.com/davidgiven/fluxengine/blob/master/doc/disk-micropolis.md)
  — independent description of the VGI format ("raw, like IMG, but with the full
  sector"), 275-byte sectors, 16 hard sectors, MOD-I/MOD-II cylinder counts.
- [Micropolis 1053 II floppy drive specifications](https://www.micropolis.com/support/floppy-drives/1053-II)
  — MetaFloppy drive background corroborating the 100 TPI / 16-sector geometry.
