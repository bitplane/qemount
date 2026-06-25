---
title: Thomson floppy image (.fd)
created: 1984
system: Thomson TO7, TO8, TO9, MO5, MO6 (French 8-bit)
extensions: [".fd"]
aliases: ["Thomson FD", "thomson_525", "thomson_35", "Thomson DOS disk"]
related:
  - format/disk/sap
  - format/media/thom-cas
---

# Thomson floppy image (.fd)

A raw sector image of a floppy disk from the Thomson family of French 8-bit
computers (TO7, TO8, TO9, MO5, MO6 and relatives), as used with the CD 90-640
and similar disk controllers. The `.fd` file is a flat, headerless dump of the
decoded sector data in track/side order; it carries no container signature and
is recognised by its size and geometry.

## Structure

MAME implements two physical families, both using 16 sectors per track:

- **Thomson 5.25-inch** (`thomson_525`):
  - SSSD (FM): 1 head, 40 tracks, 16 × 128-byte sectors
  - SSDD (MFM): 1 head, 40 tracks, 16 × 256-byte sectors
  - DSDD (MFM): 2 heads, 40 tracks, 16 × 256-byte sectors
- **Thomson 3.5-inch** (`thomson_35`):
  - SSDD (MFM): 1 head, 80 tracks, 16 × 256-byte sectors
  - DSDD (MFM): 2 heads, 80 tracks, 16 × 256-byte sectors

Typical capacities run from 80 KB up to 320 KB. (MAME notes that 1280 KB `.fd`
images for a theoretical dual-drive configuration exist but are not supported.)
There is no header to strip — the loader picks the variant from the file length
and selected drive geometry.

The Thomson world also uses two sibling containers for the same disks: the
**SAP** archival format (`.sap`, an error-checked, lightly obfuscated sector
archive — see `format/disk/sap`) and the QuickDisk `.qd` images used by the
CQ 90-028 2.8-inch QuickDisk drive. The plain `.fd` here is the unwrapped
sector form; SAP wraps the same sectors with per-sector framing and a checksum.

## References

- MAME source: `src/lib/formats/thom_dsk.cpp` — defines `thomson_525`
  ("Thomson 5.25 disk image") and `thomson_35` ("Thomson 3.5 disk image"),
  16-sector FM/MFM geometries, extension `fd`.
- A. Miné, "Thomson TO7 Emulation in MESS" (lip6.fr) — TO7 disks as `.sap`/`.fd`
  (80–320 KB) and 2.8-inch QuickDisk `.qd` (~50 KB); lists the CD 90-640,
  CD 90-015 and CQ 90-028 controllers.
- Wikipedia, "List of floppy disk formats" / HxC2001 forum — Thomson 3.5-inch
  and QuickDisk geometry corroboration.
