---
title: NFD (T98-Next PC-98 floppy image)
created: unknown
system: NEC PC-98 series (Japan)
extensions: [".nfd"]
aliases:
  - T98-Next disk image
  - NFD r0
  - NFD r1
related:
  - format/disk/dip
  - format/disk/fdd
  - format/disk/d88
  - format/pt/pc98
  - format/disk/pc98
  - format/disk/pc98fdi
  - format/disk/raw
---

# NFD (T98-Next PC-98 floppy image)

NFD is the native floppy-disk image format of the T98-Next emulator for the NEC
PC-9800 (PC-98) series of Japanese personal computers. Like [D88](d88) and
[FDD](fdd) it preserves per-sector metadata rather than storing a flat dump, so
it can faithfully represent mixed sector sizes, deleted-data marks and the kind
of irregular layouts used by copy protection. It is one of the common PC-98
floppy container formats alongside D88, [DIP](dip), FDI and the Virtual98 FDD.

The format exists in two revisions, distinguished by a signature string at the
very start of the file.

## Structure

The file is a header followed by sector data. The header opens with an
identification string and a free-text comment field, and records the header
length (a 32-bit value the loader reads near offset 0x110) so the data area can
be located.

- **r0** (`T98FDDIMAGE.R0`) uses a simple fixed sector map: one 16-byte entry per
  sector for a fixed maximum of 163 tracks × 26 sectors. Each entry carries the
  sector's C/H/R/N geometry (cylinder, head, record, and an N size code where
  `bytes = 128 << N`), an MFM flag, a deleted-data (DDAM) flag, and FDC status
  bytes.
- **r1** (`T98FDDIMAGE.R1`) extends this with a track-indexed layout — an
  overall-information part, a per-track sector-information part, and a
  special/extra-read-information part for unusual or weak-sector data — allowing
  more compact and more expressive images than r0.

The loader supports the usual PC-98 capacities, including 640 KB 2DD and 1.2 MB
2HD disks.

## Detection

MAME and the PC-98 imaging documentation agree that an NFD file begins, at offset
0, with the ASCII identification string `T98FDDIMAGE.R0` or `T98FDDIMAGE.R1`; the
trailing `R0`/`R1` selects the revision and therefore the header and sector-map
layout.

## References

- MAME loader: [`src/lib/formats/nfd_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/nfd_dsk.cpp)
  — checks `T98FDDIMAGE.R0` / `.R1` at 0x00; header length near 0x110; 16-byte
  sector-map entries; 2DD and 2HD geometries.
- [NFD r0 File Format — pc98.org](https://www.pc98.org/project/doc/nfdr0.html)
  — `T98FDDIMAGE.R0` magic, 0x100 comment, fixed 163×26 sector map, C/H/R/N
  entry fields.
- [NFD r1 File Format — pc98.org](https://www.pc98.org/project/doc/nfdr1.html)
  — `T98FDDIMAGE.R1` magic and the overall / sector / special-read header parts.
</content>
