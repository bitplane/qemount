---
title: OS-9 disk image
created: 1979
system: Microware OS-9 (6809/68k — CoCo, SWTPC, Gimix and others)
extensions: [".os9", ".dsk"]
aliases:
  - OS9 disk image
  - os9_dsk
related:
  - format/fs/coco-os9
  - format/disk/coco-rawdsk
  - format/disk/jvc
---

# OS-9 disk image

Microware OS-9 was a real-time, Unix-influenced operating system, first for the
Motorola 6809 (1979/1980) and later the 68000 family, used on machines such as
the Tandy Color Computer (CoCo), SWTPC and Gimix systems. This format is the
raw **disk-image container** for OS-9 floppies: a flat dump of the disk's
sectors whose geometry is recovered by reading the OS-9 identification sector,
rather than being fixed by the file's extension or size alone.

It sits at the *disk* layer, below the OS-9 RBF filesystem. The on-disk
directory/file structure that lives inside one of these images is documented
separately as the [OS-9 RBF filesystem](../fs/coco-os9.md); this entry covers
how MAME recognises the image and works out its track/side/sector geometry. The
two are deliberately split: `os9_dsk` is generic across OS-9 host machines and
only cares about geometry, whereas `fs/coco-os9` is the CoCo-specific filesystem
reader.

## Identification sector (LSN 0)

There is no magic number. MAME reads the OS-9 disk-descriptor in logical sector
0 and matches the values it finds against a table of known OS-9 geometries,
checking that they are self-consistent with the image's total size. The fields
it relies on include:

- Offset `0x00` (3 bytes, big-endian): total number of sectors on the volume
  (`DD.TOT`).
- Offset `0x10` (1 byte): a flag whose low bit selects single- vs double-sided.
- Offset `0x11` (2 bytes, big-endian): sectors per track.

When present, an optional device-descriptor area near offset `0x3F` supplies
further detail — a CoCo type marker, FM/MFM density, cylinder and side counts,
sectors per track, track-0 sector count, and interleave — letting the loader
distinguish CoCo discs (which number sectors from 1) from other OS-9 discs
(numbered from 0) and cover 5.25", 8" and 3.5" drives at single, double and quad
density with 256-byte sectors. All multi-byte values are stored Motorola
(big-endian) order, consistent with the 6809/68k lineage.

Because the format carries no signature and is identified by its LSN 0
descriptor and geometry rather than a fixed magic, no detection signature is
promoted here.

## References

- MAME loader: [`src/lib/formats/os9_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/os9_dsk.cpp)
- [OS-9 Disk Format — Graham's Dragon Page](http://dragon32.info/info/os9formt.html)
- [OS-9 Technical Manual §7 — Disk File Organization (icdia.co.uk)](http://www.icdia.co.uk/microware/tech/tech_7.pdf)
- [Microware OS-9/6809 — roug.org](https://www.roug.org/retrocomputing/os/os9)
