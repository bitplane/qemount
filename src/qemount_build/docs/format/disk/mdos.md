---
title: Motorola MDOS Disk Image
created: c. 1976
system: Motorola EXORciser (M6800)
extensions: [".dsk"]
aliases: [MDOS, EXORdisk, "EXORciser disk"]
related:
  - format/disk/flex
  - format/disk/fdos
  - format/disk/cp68
---

Motorola MDOS (the disk operating system for the EXORdisk floppy subsystem of the
Motorola EXORciser, an M6800 microprocessor development system) stored its data on
8-inch single-density diskettes. This format is the sector-image dump of such a
disk as read by MAME's floppy tooling.

The geometry is the classic IBM 3740 single-density layout: 77 tracks, 26 sectors
per track and 128-byte sectors, recorded with FM encoding. MAME supports both a
single-sided variant and a double-sided variant; on the double-sided disk the
second side continues the sector numbering of the first rather than restarting,
so a cylinder presents 52 logically consecutive sectors. As an 8-inch
single-density disk the on-wire layout is largely IBM 3740 compatible, with
Motorola-specific gap sizing.

The image itself is a plain sector dump with no file-level magic. MAME recognises
it heuristically by inspecting the MDOS disk-identification sector (ASCII id,
version, revision, a DDMMYY date and user fields) and by following the Resource
Information Block (RIB) cluster chain and allocation tables for internal
consistency, rather than by any fixed signature. Because identification depends on
filesystem structure rather than a header, no Detection section is given here.

MDOS is a distinct format from the SWTPC 6800 disk worlds (FLEX, FDOS and the
related CP68 layout) even though all targeted the Motorola 6800 CPU; they used
different controllers, geometries and on-disk structures.

## References

- MAME source: `src/lib/formats/mdos_dsk.cpp`
  (https://github.com/mamedev/mame/blob/master/src/lib/formats/mdos_dsk.cpp)
- Motorola *M68MDOS3 EXORdisk II/III Operating System User's Guide* and *EXORdisk
  Floppy Disk System User's Guide*, bitsavers archive
  (https://archive.org/details/bitsavers_motorola68EXORdiskIIIIIOperatingSystemUsersGuideDe_26978689)
- jhallen, *exorsim* — Motorola M6800 EXORciser / SWTPC emulator
  (https://github.com/jhallen/exorsim)
