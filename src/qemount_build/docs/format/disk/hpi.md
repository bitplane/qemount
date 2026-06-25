---
title: HPI (HP 8-inch floppy image)
created: 1980
system: HP 9885 / HP 9895A 8" floppy drives (HP-IB)
extensions: [".hpi"]
aliases:
  - HP disk image
  - HP9895 image
  - HPDir image
related:
  - format/fs/hp98x5
  - format/fs/hp-lif
  - format/disk/hp300
  - format/disk/hp-ipc
---

# HPI (HP 8-inch floppy image)

`.hpi` is the de facto container extension for raw images of Hewlett-Packard
flexible discs, established by the HPDir / HPDrive tools used to read, emulate,
and preserve vintage HP drives. MAME's `hpi_dsk` loader handles the 8-inch
variant: a sector-by-sector image of an HP-formatted 8" floppy as written by the
HP 9885 and HP 9895A HP-IB drives.

This is the **image / disk-surface layer**, distinct from the filesystems that
live inside such images — HP's record-based 98x5 directory format
(`format/fs/hp98x5`) and the later LIF volume format (`format/fs/hp-lif`), both
of which are commonly distributed as `.hpi` files.

## Structure

The image is a flat dump of every sector in cylinder/head/sector order with no
header or trailer — a full double-sided 77-track disc is exactly 1,182,720
bytes. MAME recognises four geometries, all 30 sectors/track of 256 bytes:

- single-sided: 67 or 77 cylinders, 1 head;
- double-sided: 75 or 77 cylinders, 2 heads.

On the wire these HP 8" discs use HP's MMFM/M2FM bit encoding (LSB first) with
HP-specific ID and data address marks and a CRC-16 over each field; the loader
also applies a sector interleave (default factor 7) when mapping the linear file
to physical sectors. The image file itself, however, holds only decoded sector
data with no magic, so no signature-based detection is defined here.

## References

- MAME loader: [`src/lib/formats/hpi_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/hpi_dsk.cpp)
- [The HPDir Project (hp9845.net)](https://www.hp9845.net/9845/projects/hpdir/index.html)
- [The HPDrive Project (hp9845.net)](https://www.hp9845.net/9845/projects/hpdrive/)
- [HP 9895A 8" floppy drive — HP Computer Museum](https://www.hpmuseum.net/display_item.php?hw=262)
