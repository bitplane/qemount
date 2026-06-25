---
title: PC raw floppy image
created: unknown
system: IBM PC and compatibles
extensions: [".img", ".ima", ".dsk", ".ufi", ".360"]
aliases:
  - pc_dsk
  - PC floppy image
  - raw PC disk image
related:
  - format/disk/pc98
  - format/disk/raw
  - format/fs/fat12
---

# PC raw floppy image

A raw, headerless sector dump of an IBM PC (or compatible) floppy disk — the
plainest disk image there is, just every 512-byte sector copied out in
cylinder/head/sector order with nothing in front of it. This is the `.img`/`.dsk`
form MESS/MAME use for ordinary PC floppies, and the same content carried by
countless `.ima`/`.img` images elsewhere. The sectors normally hold a FAT12
filesystem.

With no header to read, MAME identifies the geometry purely from the file's size,
matching it against a table of standard PC formats. All use 512-byte sectors and
MFM encoding:

| Size | Drive | Tracks | Sides | Sectors/track |
|------|-------|--------|-------|---------------|
| 160 KB | 5.25" | 40 | 1 | 8 |
| 180 KB | 5.25" | 40 | 1 | 9 |
| 320 KB | 5.25" | 40 | 2 | 8 |
| 360 KB | 5.25" | 40 (also 41/42) | 2 | 9 |
| 400 KB | 5.25" | 40 | 2 | 10 |
| 720 KB | 5.25"/3.5" | 80 | 2 | 9 |
| 1200 KB | 5.25"/3.5" (JP) | 80 | 2 | 15 |
| 1440 KB | 3.5" | 80 | 2 | 18 |
| 1680 KB | 3.5" (DMF) | 80 | 2 | 21 |
| 2880 KB | 3.5" | 80 | 2 | 36 |

Because identification is by exact size only, sizes that two geometries share
(or non-standard images) are ambiguous, and the format carries no metadata to
disambiguate. No detection rule is asserted: size-based matching collides badly,
and a raw FAT12 floppy is better recognised by its boot sector / BPB than by the
container.

This is the IBM-PC counterpart to the headerless [PC-98 raw image](pc98), which
reuses several of the same extensions but uses PC-98 geometries (256- and
1024-byte sectors, 77-cylinder 2HD). With no header on either, an image's true
identity is its geometry, not its extension.

## References

- MAME source: [`src/lib/formats/pc_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/pc_dsk.cpp)
  — headerless 512-byte-sector raw image; geometry chosen from file size against
  the standard-PC table above.
- [Disk image — Wikipedia](https://en.wikipedia.org/wiki/Disk_image)
  — describes raw `.img` sector dumps as flat copies of every sector with no
  header.
- [FAT — Wikipedia](https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system)
  — the standard 360 KB / 720 KB / 1.44 MB PC floppy geometries and their BPB
  fields, which are what actually identify a raw PC floppy image.
