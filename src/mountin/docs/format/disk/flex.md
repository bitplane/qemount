---
title: FLEX disk image
created: 1976
system: Motorola 6800 / 6809 (FLEX operating system)
extensions: [".dsk"]
aliases:
  - FLEX
  - Flex09
  - TSC FLEX
related:
  - format/disk/fdos
  - format/disk/cp68
  - format/fs/coco-os9
  - format/disk/raw
---

# FLEX disk image

FLEX is a single-tasking disk operating system written by Technical Systems
Consultants (TSC) of West Lafayette, Indiana, first released in 1976 for the
Motorola 6800 and later ported to the 6809 (as Flex09 / 6809 FLEX). It was widely
used on SWTPC and other 6800/6809 machines. This format is the on-disk image of a
FLEX-formatted floppy.

FLEX disks use soft-sectored, 256-byte sectors. Files are stored as linked lists:
every sector reserves its first two bytes as a pointer to the next sector in the
file (or in the free-sector chain), which keeps the directory structure simple. A
**System Information Record (SIR)**, conventionally at track 0 sector 3 (sector 2
in zero-based addressing), records the disk name, the free-chain head and tail,
the sector count and the track/sector geometry — that record is the structural
anchor MAME uses to validate an image.

MAME's loader supports a wide range of FLEX geometries through its WD177x layout:
5.25" single/double/quad density (35–80 tracks, 10–18 sectors), 8"
single/double density (77 tracks, 15–26 sectors) and 3.5" high density (80
tracks, 36 sectors), with 128- or 256-byte sectors. Sector interleave is applied
to suit slower hardware, and track 0 is often formatted in single density even on
double-density disks so simple ROM boot code can read it. There is no fixed magic
signature; the loader sniffs the boot sector for 6800 boot patterns (`0x8E`
stack-load followed by a `0x20` branch) to choose between sector-numbering
schemes, then cross-checks the SIR and file size.

## References

- MAME source: `src/lib/formats/flex_dsk.cpp`
  (https://github.com/mamedev/mame/blob/master/src/lib/formats/flex_dsk.cpp)
- FLEX (operating system), Wikipedia:
  https://en.wikipedia.org/wiki/FLEX_(operating_system)
- 6809 FLEX Adaptation Guide (TSC), with disk-format appendices:
  http://flexusergroup.com/flexusergroup/pdfs/6809fadg.pdf
- FLEX 2.0 for SWTPC 6800 (deramp.com):
  https://deramp.com/swtpc.com/FLEX20/Flex20_Index.htm
