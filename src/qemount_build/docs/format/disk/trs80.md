---
title: TRS-80 JV1 / JV3 disk image
created: 1990s
system: TRS-80 (Tandy/Radio Shack Models I, III, 4)
extensions: [".jv1", ".jv3", ".dsk"]
aliases:
  - JV1 disk image
  - JV3 disk image
  - Jeff Vavasour disk image
related:
  - format/disk/dmk
  - format/disk/raw
  - format/media/trs80-cas
---

# TRS-80 JV1 / JV3 disk image

Two related sector-image formats for Tandy/Radio Shack TRS-80 floppy disks,
both originated by Jeff Vavasour ("JV") for his MS-DOS TRS-80 emulators and
later documented in detail by Tim Mann. They are the simple sector-dump
counterparts to the lower-level [DMK](dmk) track image, which preserves the raw
controller bitstream; JV1/JV3 store only decoded sector contents and so cannot
represent copy-protected or scrambled disks.

## JV1

The simplest TRS-80 image: an unadorned array of 256-byte sectors with **no
header**, intended for the Model I with Level II BASIC. Byte 0 of the file is
the first byte of track 0 / sector 0, the next 256 bytes are sector 1, and so
on. It can only represent single-sided, single-density media with 10 sectors of
256 bytes per track; the track count is open-ended (35-, 40- and 80-track disks
are typical). The Model I directory lives on track 17.

## JV3

A more flexible image for the Models III and 4, supporting double density,
double-sided disks, write-protect and varying sector sizes. It too has no
conventional header, but begins with a fixed **sector-descriptor table**:

- 2901 three-byte descriptors (total `0x2200` bytes including a trailing
  read-only flag byte), each describing one sector:
  - byte 0 — track number (`0xFF` marks an unused/free descriptor),
  - byte 1 — sector number,
  - byte 2 — flags packing sector size, density (FM/MFM), data-address-mark,
    CRC-error and side bits.
- the sector data blocks follow, in descriptor order.

The largest geometry MAME supports through this format is up to 2 sides, 96
tracks and 18 sectors per track.

## References

- MAME loader:
  [`src/lib/formats/trs80_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/trs80_dsk.cpp)
  (JV1 = Model I, headerless 10x256 SSSD; JV3 = Models III/4, `0x2200` of
  3-byte sector descriptors + read-only byte).
- [Common file formats for emulated TRS-80 floppy disks — Tim Mann](https://www.tim-mann.org/trs80/dskspec.html)
  (authoritative JV1/JV3 specification; both formats originated in Jeff
  Vavasour's MS-DOS emulators).
- [NewDos/80 and the JV1 disk image format — classic-computers.org.nz](https://www.classic-computers.org.nz/system-80/software-archive-disks-technical.htm)
