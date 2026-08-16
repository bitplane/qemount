---
title: SDF (CoCo SDC disk image)
created: unknown
system: Tandy/TRS-80 Color Computer (CoCo) and Dragon, via the CoCo SDC
extensions: [".sdf"]
aliases:
  - CoCoSDC SDF
  - SDF1
related:
  - format/disk/dmk
  - format/disk/jvc
  - format/disk/coco-rawdsk
---

# SDF (CoCo SDC disk image)

A track-level floppy image designed by Darren Atkinson for the **CoCo SDC**, an
SD-card floppy emulator for the Tandy/TRS-80 Color Computer (and Dragon)
6809 machines. SDF exists to represent disks whose layout is *not* the standard
18-sectors-of-256-bytes RS-DOS arrangement — copy-protected or otherwise
irregular disks that a plain sector dump cannot capture. It is essentially a
re-engineering of the older [DMK](dmk.md) track image, restructured by Atkinson
so it could be served from the limited RAM of the CoCo SDC's ATmega328
microcontroller, with every track aligned to a 512-byte boundary for efficient
SD-card access.

## Structure

The file begins with a 256-byte **file header**. The first four bytes are the
ASCII identifier `SDF1`; following bytes record the track count and the head
count (1 for single-sided, 2 for double-sided). The header is followed by one
record per track (per side).

Each track record is a 256-byte track header followed by 6250 bytes of raw MFM
track data, then 150 bytes of unused padding — 6656 bytes total, i.e. 13 × 512,
keeping each track on a 512-byte boundary. The 6250-byte track length holds
either a single-density (~125 kbps) or double-density (~250 kbps) track at
300 rpm. The track header carries the sector-location metadata for up to 16
sectors. SDF does not cover 8" or high-density (500 kbps) disks. Decoding the
raw track stream uses the usual MFM marks (IAM/IDAM/DAM, clock patterns 0x5224
and 0x4489).

## Detection

MAME and the CoCo SDC documentation agree that the file opens with the four
ASCII bytes `SDF1` (`53 44 46 31`), marking a version-1 SDF image. The head
count in the header must be 1 or 2.

## References

- MAME loader: [`src/lib/formats/sdf_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/sdf_dsk.cpp)
  (256-byte header, magic `SDF1`, track/head counts, MFM marks 0x5224/0x4489)
- [CoCo SDC: Disk Image Formats — cocosdc.blogspot.com](http://cocosdc.blogspot.com/p/sd-card-socket-sd-card-socket-is-push.html)
  (`SDF1` magic; per-track 256-byte header + 6250 raw bytes + 150 pad, 512-byte aligned; DMK derivative)
- [CoCo SDC User Guide (Darren Atkinson) — Color Computer Archive](https://colorcomputerarchive.com/repo/Documents/Manuals/Hardware/CoCo%20SDC%20User%20Guide%20v4%20(Darren%20Atkinson).pdf)
- [CoCoSDC — CoCopedia](https://www.cocopedia.com/wiki/index.php/CoCoSDC)
