---
title: Nokia MikroMikko Disk Image
created: 1981
system: Nokia MikroMikko (Nokia Data)
extensions: [".dsk"]
aliases: [MikroMikko, "Mikro Mikko", MM1, MM2, mm_dsk]
related:
  - format/fs/cpm
  - format/fs/fat12
---

MikroMikko was a line of business microcomputers built by Nokia's computer
division, Nokia Data, in Finland. The first model, MikroMikko 1, launched on 29
September 1981 — weeks after the original IBM PC — around an Intel 8085 CPU
running Nokia's CP/M, with later models moving to Nokia MS-DOS. This format is the
raw sector-image dump of a MikroMikko floppy as handled by MAME.

There is no file header or magic; the loader is a set of fixed UPD765-style
geometry descriptions:

- **MikroMikko 1 (MM1):** 80 tracks, 2 heads, 8 sectors per track, 512-byte
  sectors — i.e. a 640 KB double-sided 5.25-inch disk, matching the 640 KB drives
  the machine shipped with.
- **MikroMikko 2 (MM2):** 40 tracks, 2 heads, 512-byte sectors, in either a
  9-sectors-per-track (DSDD) or an 18-sectors-per-track variant. The MAME source
  flags the 18-sector case as questionable (it implies HD density at 300 rpm) and
  marks some gap sizes as unverified.

Because the images are bare fixed-geometry sector dumps with no signature, no
Detection section is given and no size-based rule is implied.

## References

- MAME source: `src/lib/formats/mm_dsk.cpp`
  (https://github.com/mamedev/mame/blob/master/src/lib/formats/mm_dsk.cpp)
- "MikroMikko", Wikipedia
  (https://en.wikipedia.org/wiki/MikroMikko)
- Nokia MikroMikko 1, IT History Society
  (https://www.ithistory.org/db/hardware/nokia/nokia-mikromikko-1)
