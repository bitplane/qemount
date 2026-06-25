---
title: JVC disk image (CoCo)
created: 1990s
system: Tandy/TRS-80 Color Computer (CoCo)
extensions: [".jvc", ".dsk"]
aliases:
  - JV1
  - JV3
  - Jeff Vavasour CoCo disk
  - CoCo DSK
related:
  - format/disk/coco-rawdsk
  - format/disk/dmk
  - format/fs/coco-rsdos
  - format/fs/coco-os9
---

# JVC disk image (CoCo)

JVC is the sector-dump disk image format named for Jeff Vavasour, author of a
widely used family of 1990s Tandy/TRS-80 Color Computer (CoCo) emulators. It is
the most common container for CoCo floppy images and stores the data portion of
each sector in order of track, then side, then sector — essentially a raw dump
with an optional, variable-length descriptive header tacked on the front. The
plain `.dsk` files that hold an [RS-DOS / Disk BASIC](../fs/coco-rsdos.md) or
[OS-9 RBF](../fs/coco-os9.md) filesystem are usually JVC images.

## Header

The header is unusual in that its length is implied rather than recorded: a
reader takes the file length modulo 256, and that remainder (0–255 bytes) is the
header size. Sector data begins immediately after it. Most images in the wild
have a header length of zero — they are a bare, headerless sector dump of an
18-sector, 256-byte, 35- or 40-track single-sided disk, identical in payload to
the [CoCo raw disk image](coco-rawdsk.md).

When present, the header overrides the default geometry one byte at a time, so a
1-byte header sets only the first field, a 2-byte header the first two, and so
on:

| Offset | Field | Default |
|--------|-------|---------|
| 0 | Sectors per track | 18 |
| 1 | Side count | 1 |
| 2 | Sector size code (0=128, 1=256, 2=512, 3=1024 bytes) | 1 (256) |
| 3 | First sector ID | 1 |
| 4 | Sector attribute flag | 0 |

If the sector-attribute flag is set, every sector is preceded by an attribute
byte mirroring the bits a WD279x floppy controller would set after a read (record
type, record-not-found, CRC error), allowing copy-protection quirks to be
represented. By convention an image of more than 80 tracks is taken to be
double-sided with the two sides interleaved, a backward-compatible hack for
double-sided disks. The format is closely related to the earlier JV1/JV3 sector
dumps from the TRS-80 world and is far simpler than the track-level
[DMK](dmk.md) format, which preserves address marks and gaps.

There is no magic signature; the format is identified by extension, by the
header-size-from-file-length rule, and by context, so no detection rule is given
here.

## References

- MAME loader: [`src/lib/formats/jvc_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/jvc_dsk.cpp) ("Used by Jeff Vavasour's CoCo Emulators")
- [JVC Disk Format — DaBarnStudio](https://sites.google.com/site/dabarnstudio/coco-utilities/jvc-disk-format)
- [CoCo SDC: Disk Image Formats — cocosdc.blogspot.com](http://cocosdc.blogspot.com/p/sd-card-socket-sd-card-socket-is-push.html)
