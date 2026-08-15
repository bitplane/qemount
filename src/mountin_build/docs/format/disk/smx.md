---
title: Specialist MX disk image (SMX)
created: unknown
system: Specialist MX / Orion / B2M (Soviet 8080/Z80 DIY computers)
extensions: [".odi", ".cpm", ".img"]
aliases:
  - SMX disk
  - Specialist MX floppy
  - Orion disk image
  - B2M disk image
related:
  - format/disk/dvk-mx
  - format/disk/agat840k
  - format/disk/pyldin
---

# Specialist MX disk image (SMX)

A raw, fixed-geometry floppy image used by several Soviet hobbyist
microcomputers: the **Specialist MX** (an enhanced disk-capable descendant of
the DIY "Specialist"/Специалист computer first published in *Modelist-Konstruktor*
in the late 1980s), the **Orion-128**, and the **B2M**. These were
amateur-built 8080/Z80-class machines that shared a good deal of software and,
later, floppy-disk hardware.

MAME's loader is built on its generic `wd177x_format` base — the Western Digital
WD1770/WD1772-style controller framework — so the image is a flat dump of the
disk's sectors with no container header or magic number.

## Structure

Two double-sided, quad-density 5.25" geometries are recognised, both MFM:

**Specialist MX / Orion / B2M:**

- 80 tracks, 2 heads
- 5 sectors per track, 1024 bytes per sector (≈ 800 KB)

**Lucksian Key Orion:**

- 80 tracks, 2 heads
- 9 sectors per track, 512 bytes per sector (≈ 720 KB)

Because both are headerless raw sector dumps, there is no in-band signature;
identification rests on the `.odi` / `.cpm` / `.img` extension, the total size,
and context rather than a magic number. (MAME's own comments flag the precise
inter-sector gap sizes as unverified.)

The `.cpm` extension reflects that these machines ran CP/M-80 from disk; `.odi`
("Orion Disk Image") is the common Orion-128 container.

## References

- MAME loader: [`src/lib/formats/smx_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/smx_dsk.cpp)
- [Specialist (computer) — Wikipedia](https://en.wikipedia.org/wiki/Specialist_(computer))
- [Orion-128 — Wikipedia](https://en.wikipedia.org/wiki/Orion-128)
