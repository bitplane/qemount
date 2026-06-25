---
title: SAP (Systeme d'Archivage Pukall)
created: 1998
system: Thomson TO/MO (TO7, TO7/70, TO8, TO9, MO5, MO6)
extensions: [".sap"]
aliases:
  - Systeme d'Archivage Pukall
  - Pukall disk archive
related:
  - format/disk/thom
  - format/media/thom-cas
---

# SAP (Systeme d'Archivage Pukall)

A container image for floppy disks of the Thomson family of French 8-bit home
computers (the MO and TO ranges sold by Thomson SA in the mid-1980s). SAP was
written by Alexandre Pukall in April 1998 as a way to archive physical Thomson
3.5" and 5.25" disks into single files that emulators read and write directly,
preserving the contents independently of the ageing media. The acronym expands
to **Systeme d'Archivage Pukall** (Pukall Archiving System).

Unlike a flat sector dump, a SAP file is a sector-level archive with per-sector
framing and a light obfuscation pass: the stored sector payloads are
XOR-scrambled with the constant `0xB3`, and each sector carries its own address
header and a CRC. The intent was robust archival (detecting bad sectors) rather
than a mountable on-disk filesystem; the Thomson filesystem itself sits inside
the decoded sector data.

## Structure

The file opens with a fixed 66-byte header: a single **disk-type byte** at
offset 0 followed by a 65-byte ASCII copyright/identification string. The
type byte encodes the geometry as bit flags — density (FM 128-byte sectors vs.
MFM 256-byte sectors), track count (40 for 5.25", 80 for 3.5"), and single- vs.
double-sided.

After the header come the sector records. Each record holds a short address
field (track, side, sector number, and a size/format code), the sector data,
and a 16-bit CRC. The data bytes are XOR-ed with `0xB3` on the way in and out.
Common geometries are a 160 KB 5.25" disk (40 tracks, 16 × 256-byte sectors per
track) and a 320 KB 3.5" disk (80 tracks). The format is fully compatible with
TO7, TO7/70, TO9 and MO5 disk images.

## Detection

Both MAME's loader and the Thomson emulator community describe the same fixed
signature: the disk-type byte at offset 0 is immediately followed by the ASCII
string `SYSTEME D'ARCHIVAGE PUKALL S.A.P. (c) Alexandre PUKALL Avril 1998`
beginning at offset 1, giving a 66-byte header. The string is a reliable
identifier; the leading byte varies because it carries the geometry flags.

## References

- MAME loader: [`src/lib/formats/sap_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/sap_dsk.cpp)
  (66-byte Pukall header, per-sector framing, payload XOR `0xB3`, CRC per sector)
- [Archiver une disquette Thomson vers une archive SAP — logicielsmoto.com](http://www.logicielsmoto.com/sap2.php)
- [teo-emulator wiki: SAP2 format notes](https://sourceforge.net/p/teoemulator/wiki/sap2_fr/)
- [Format des disquettes pour emulateur — system-cfg.com forum](https://forum.system-cfg.com/viewtopic.php?t=7483)
