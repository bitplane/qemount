---
title: IBM Extended Density Format (XDF)
created: 1994
system: IBM PC DOS 7 / OS/2 (PC floppy distribution media)
extensions: [".xdf", ".img"]
aliases:
  - XDF
  - eXtended Density Format
related:
  - format/fs/fat12
  - format/disk/raw
  - format/disk/x68000-xdf
---

# IBM Extended Density Format (XDF)

XDF is a "super-format" devised by IBM to squeeze extra capacity out of an
ordinary high-density floppy without special media. By using a small number of
large sectors per track instead of many standard 512-byte sectors, XDF cuts
inter-sector overhead and raises a 1.44 MB 3.5" HD diskette to roughly 1.86 MB
(and a 5.25" HD diskette to about 1.54 MB). IBM used it for the floppy
distribution sets of PC DOS 7 and OS/2 Warp 3 onward; both OSes can read and
create XDF media with the bundled `XDFCOPY` / `XDF` tools.

The trick is mixed sector sizes within a track. In MAME's loader the 3.5" HD
variant uses 80 cylinders, two heads, MFM encoding. Cylinder 0 is laid out with
standard 512-byte sectors and a bespoke sector-numbering scheme so it can be
read by an ordinary BIOS/FAT12 driver without XDF support — that first cylinder
typically carries a tiny FAT12 area and a readme or the XDF driver. The
remaining cylinders pack sectors of 1024, 512, 2048 and 8192 bytes with
interleaved, side-tagged sector IDs.

Because the first cylinder is a normal FAT12 boot area, an XDF image is a
PC-style raw sector dump (often carrying the generic `.img` extension as well as
`.xdf`) rather than a tagged container; it has no magic signature. MAME
recognises the 3.5" HD variant by its exact total image length (1,884,160
bytes). A hardware caveat worth noting: XDF media can only be accessed through a
floppy controller wired directly to the system — USB floppy drives cannot read
it.

Do not confuse this with the unrelated Sharp X68000 "XDF" floppy image
(`format/disk/x68000-xdf`), which shares the `.xdf` extension and the "XDF"
abbreviation but is a plain Japanese 2HD sector dump for Human68k, not IBM's
mixed-sector PC scheme. They share only the three letters.

## References

- MAME loader: [`src/lib/formats/ibmxdf_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/ibmxdf_dsk.cpp)
- [IBM Extended Density Format — Wikipedia](https://en.wikipedia.org/wiki/IBM_Extended_Density_Format)
- [The XDF Diskette Format — OS/2 Museum](http://www.os2museum.com/wp/the-xdf-diskette-format/)
- [XDF (Extended Density Format) — Just Solve the File Format Problem](http://justsolve.archiveteam.org/wiki/XDF_(Extended_Density_Format))
