---
title: PC-98 FDI (Anex86 disk image)
created: unknown
system: NEC PC-98 series (Japan)
extensions: [".fdi"]
aliases:
  - pc98_fdi
  - Anex86 FDI
  - Anex86 floppy disk image
related:
  - format/disk/fdi
  - format/disk/pc98
  - format/disk/dip
  - format/disk/fdd
  - format/disk/d88
  - format/pt/pc98
  - format/disk/raw
---

# PC-98 FDI (Anex86 disk image)

FDI here is the floppy-disk image format of **Anex86**, a popular emulator of the
NEC PC-9800 (PC-98) series. It is a raw PC-98 sector dump (the same body as an
[HDM/PC-98 raw image](pc98)) preceded by a self-describing header that records
the disk geometry. Anex86's companion hard-disk format, HDI, uses the same header
layout — the two are essentially one format, with FDI conventionally used for
floppies (two heads or fewer) and HDI for hard disks.

> **Not to be confused with the other `.fdi`.** This is a different format from
> the Vincent Joguin "[Formatted Disk Image](fdi)" preservation container, which
> also uses the `.fdi` extension. The Joguin format opens with the ASCII magic
> `Formatted Disk Image file` and stores per-track, flux-level data; the Anex86
> format below has no ASCII magic and is a plain header plus raw sectors. They
> share only the extension. See [disk/fdi](fdi) for the collision noted from the
> other side.

## Structure

The file begins with a header whose own length is stored in a field, then the raw
sector data. All fields are 32-bit little-endian. MAME reads the first 32 bytes:

| Offset | Size | Field |
|--------|------|-------|
| 0x00 | 4 | Reserved (must be zero) |
| 0x04 | 4 | FDD type identifier |
| 0x08 | 4 | Header size in bytes (Anex86 "New Disk" default is 4096; 32 is the minimum, meaning no comment area) |
| 0x0C | 4 | Data size — total bytes of sector data |
| 0x10 | 4 | Bytes per sector |
| 0x14 | 4 | Sectors per track |
| 0x18 | 4 | Heads (sides) |
| 0x1C | 4 | Cylinders (tracks) |

Sector data starts at the offset given by the header-size field — 4096 in the
common Anex86 case, where the 32 bytes of fields are followed by 4064 padding
bytes. The geometry is uniform: every track has the same sector size and sector
count. MAME rebuilds MFM tracks from the flat data using its PC sector/track
helpers.

## Detection

Two independent sources — MAME's loader and the pc98.org / Anex86 format
documentation — agree that there is no ASCII magic. Instead the file is validated
structurally: the total file size must equal *header size + data size*, and the
data size must equal *bytes-per-sector × sectors × heads × cylinders*. That
consistency check (rather than any signature) is what distinguishes a genuine
Anex86 FDI, and it is why this format cannot be told apart from the unrelated
Joguin `.fdi` by extension alone — only the Joguin format carries an ASCII
signature. No `detect:` rule is asserted in this pass.

## References

- MAME source: [`src/lib/formats/pc98fdi_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/pc98fdi_dsk.cpp)
  — reads a 32-byte little-endian header (header size at 0x08, data size at 0x0C,
  sector size / sectors / heads / cylinders at 0x10–0x1C); validates by
  size == hsize + psize and psize == ssize × scnt × sides × ntrk.
- [HDI / FDI File Format — pc98.org](https://www.pc98.org/project/doc/hdi.html)
  — Anex86 header layout; header size default 4096, minimum 32; FDI/HDI
  interchangeable.
- [Anex86 PC98 floppy image — Just Solve the File Format Problem](http://justsolve.archiveteam.org/wiki/Anex86_PC98_floppy_image)
  — FDI as a 4096-byte little-endian header in front of a raw HDM image.
