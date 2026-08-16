---
title: FDOS disk image (SWTPC)
created: 1977
system: SWTPC 6800 (FDOS — Floppy Disk Operating System)
extensions: [".dsk"]
aliases:
  - SWTPC FDOS
  - Floppy Disk Operating System
related:
  - format/disk/flex
  - format/disk/cp68
  - format/disk/raw
---

# FDOS disk image (SWTPC)

FDOS (Floppy Disk Operating System) was the first disk operating system shipped
by Southwest Technical Products Corporation (SWTPC) for its Motorola 6800
machines, bundled with the MF-68 mini-floppy system from about August 1977. It
predates SWTPC's adoption of TSC's FLEX. This format is the on-disk image of an
FDOS-formatted floppy as handled by MAME's DC-1/DC-4/DC-5 controller support.

The geometry is a single-sided 5.25" mini-floppy: 35 tracks, 10 sectors per
track, 256 bytes per sector (~89.6 KB), decoded through MAME's WD177x sector
layout. The disk is laid out with the operating system on tracks 0–1, the
directory on track 2, and data on tracks 3–34.

FDOS images carry no magic signature. MAME identifies them heuristically by
inspecting track 0 sector 0 for 6800 boot code (a `JSR` opcode `0xBD` at byte 0,
an `LDX` opcode `0xDE` at byte 3) and by requiring the first directory entry to
be the system file `$DOS` with the expected load/end/exec addresses
(`0x2400`/`0x2FFF`/`0x2600`). MAME notes that an original bootable FDOS image is
needed to cold-start the system, after which further FDOS disks can be read.

## References

- MAME source: `src/lib/formats/fdos_dsk.cpp`
  (https://github.com/mamedev/mame/blob/master/src/lib/formats/fdos_dsk.cpp)
- SWTPC FDOS / MiniFLEX / FLEX timeline (deramp.com):
  https://deramp.com/downloads/swtpc/software/FDOS%20and%20FLEX%20Timeline.pdf
- SWTPC history and disk hardware (deramp.com): https://deramp.com/swtpc.html
- "SWTPC 6800 Video #12 FDOS (The First DOS Shipped by SWTPC)", Internet Archive:
  https://archive.org/details/swtpc-6800-video-12-fdos-the-first-dos-shipped-by-swtpc
