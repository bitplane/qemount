---
title: HP LIF (Logical Interchange Format)
created: 1980
system: Hewlett-Packard (HP 9000 / Series 80 / HP-150 / HP-IL / HP-UX)
extensions: []
aliases:
  - LIF
  - Logical Interchange Format
  - HP-LIF
related:
  - format/pt/hpux
  - format/fs/cpm
  - format/disk/imd
  - format/disk/hpi
  - format/disk/hp300
  - format/disk/hp-ipc
detect:
  # The LIF system word 0x8000 (big-endian) at offset 0 is the canonical LIF
  # signature (per file(1)'s `lif` magic and disktype). An HP-UX boot area is
  # itself a LIF volume, so this is the same marker the pt/hpux doc described.
  # The extra clauses are file(1)'s refinements that reject a DEGAS .pc1 bitmap
  # which also opens with 0x8000: word 14 is zero, the version word is small,
  # and the volume label (offset 2) is ASCII-ish.
  all:
    - offset: 0
      type: be16
      value: 0x8000
    - offset: 14
      type: be16
      value: 0
    - offset: 20
      type: be16
      value: 0x0100
      op: "<"
    - offset: 2
      type: be32
      value: 0x2020201F
      op: ">"
---

# HP LIF (Logical Interchange Format)

LIF is Hewlett-Packard's mass-storage interchange format, used across a wide
range of HP equipment from the early 1980s onward: HP 9000 workstations, the
Series 80 desktops, the HP-150, HP-IL peripherals, HP calculators, and the boot
area of HP-UX hard disks. It defines a simple, flat volume: a header identifying
the medium as LIF, a single fixed directory, and then the file data. There are
no subdirectories.

## Structure

LIF works in 256-byte records (logical sectors). The layout is:

- **Volume header** (record 0). Begins with the 16-bit LIF system word
  `0x8000`. It carries a 6-character volume label, the starting record of the
  directory, the directory length in records, and a 16-bit "LIF identifier"
  field.
- **Directory.** A contiguous run of records, each holding eight 32-byte
  entries. Each entry stores a 10-character (case-sensitive) file name, a 16-bit
  file type, the file's starting record and length in records, a BCD timestamp,
  a volume number, and an implementation-defined field. A type word of `0xffff`
  terminates the directory; `0x0000` marks a free slot.
- **File data** follows the directory, each file occupying a contiguous run of
  records described by its directory entry.

The 16-bit file-type field encodes what the file is (HP partitioned its value
space among its product divisions). Files are stored contiguously, so there is
no per-file block chain or allocation bitmap — allocation is implied by the
directory's start/length fields.

MAME's loader recognises several HP floppy geometries (HP 9121 3.5" DS/DD and
HP 9122 variants, from roughly 270 KB to 1.5 MB), but LIF itself is geometry-
independent and is also used on hard disks and tapes.

## Detection

Two independent sources (the HP-UX `lif(4)` manual page and the `lifutils`
project) agree that a LIF volume begins with the 16-bit big-endian system word
`0x8000` (bytes `80 00`) at offset 0 of the volume. This same marker is used by
the existing HP-UX disklabel doc (see `format/pt/hpux`), where LIF wraps a VTOC
in the disk's boot area; the filesystem described here is the more general LIF
volume used directly on HP media.

## References

- MAME loader: [`src/lib/formats/fs_hplif.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/fs_hplif.cpp)
- [`lif(4)` — HP-UX manual page](https://docstore.mik.ua/manuals/hp-ux/en/B2355-60130/lif.4.html)
- [bug400/lifutils — LIF file utilities](https://github.com/bug400/lifutils)
- [The HPDir Project (hp9845.net)](https://www.hp9845.net/9845/projects/hpdir/)
