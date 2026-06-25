---
title: Iskra Delta Partner disk image
created: 1983
system: Iskra Delta Partner (Slovenia / SFR Yugoslavia, Z80 business computer)
extensions: [".img"]
aliases:
  - idpart
  - Iskra Delta Partner
related:
  - format/fs/cpm
  - format/disk/raw
---

# Iskra Delta Partner disk image

Despite the "idpart" file stem looking like a partition tool, this is a raw
floppy **disk image** format for the Iskra Delta Partner — not a partition
splitter. "idpart" is short for **I**skra **D**elta **Part**ner. The Partner was
a Z80A-based business/education microcomputer built by Iskra Delta of Slovenia
(then SFR Yugoslavia) from 1983; it was the most mass-produced Slovenian
computer of its era and typically ran CP/M-style software (Turbo Pascal,
WordStar).

The MAME loader decodes the image into MFM track data for a uPD765-type floppy
controller. It models the Partner's 5.25" double-sided, quad-density media with
256-byte sectors, 18 sectors per track, and either 73 or 77 cylinders (two
capacity variants), at a 2000 ns bit-cell rate. There is no header or magic
signature — the file is a plain ordered sector dump and is matched by geometry
and size. (MAME's own source flags its gap parameters as "Unverified gap
sizes".)

Note a discrepancy worth flagging: contemporary descriptions of the Partner's
standard floppy quote 80 tracks of nine 512-byte sectors (~720 KB DS/DD), and
the ability to read MS-DOS 360 KB disks via a utility — geometry that differs
from the 18×256-byte quad-density layout MAME's loader expects. This likely
reflects different drive/format configurations used by the machine over its
life; the MAME loader targets the specific dumps in its software list.

## References

- MAME loader: [`src/lib/formats/idpart_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/idpart_dsk.cpp)
- [Iskra Delta Partner — Wikipedia](https://en.wikipedia.org/wiki/Iskra_Delta_Partner)
- [Iskra Delta Partner — Matej Horvat (SloComp)](http://matejhorvat.si/en/slocomp/delta/partner/index.htm)
- [Iskra Delta Partner — old-computers.com museum](https://www.old-computers.com/museum/computer.asp?c=53)
