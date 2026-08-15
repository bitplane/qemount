---
title: JFD (JASPP Floppy Disk)
created: 2010s
system: Acorn Archimedes / RISC OS (ADFFS emulation)
extensions: [".jfd"]
aliases:
  - JASPP Floppy Disk
  - JFDI
  - ADFFS floppy image
related:
  - format/disk/adf
  - format/disk/acorn
  - format/disk/raw
---

# JFD (JASPP Floppy Disk)

JFD is the disc-image container used by **ADFFS**, the floppy/disc emulator
developed for the Archimedes Software Preservation Project (**JASPP**). It
exists to preserve copy-protected Acorn Archimedes / RISC OS floppies — keeping
the original protection intact — and is the format JASPP distributes its
preserved game images in. JFD images are usable only under ADFFS, which
emulates the WD1772 floppy controller (and, on later hardware, more of the
chipset) so the protected discs still load on modern machines.

Despite the superficial name clash, this is **not** the Oric "Jasmin" disc
format covered by `fs/oric-jasmin` — the two are unrelated. JFD here is an
Acorn/RISC OS preservation container.

## Structure

Per MAME's loader, a JFD file begins with a header identified by the ASCII tag
`JFDI`, optionally wrapped in gzip compression (a leading `1f 8b`, transparently
inflated before parsing). The header records, among other fields, the minimum
ADFFS version required, the uncompressed size, a disc-set sequence number, an
official game/release ID, an image version, a disc title, feature flags, and
offsets to four tables:

- **Track table** — one 32-bit offset per track (`0xffffffff` marks an
  unformatted track).
- **Sector table** — per-track sector entries pairing a sector header with a
  data offset, terminated by `0xffffffff`.
- **Data table** — the raw sector payloads.

Sector headers carry the cylinder/head, the sector number and size
(128/256/512/1024 bytes), a density multiplier, and CRC/protection flags — the
detail needed to reproduce odd, copy-protected track layouts rather than just a
clean sector image. Because the image carries identity metadata (the game ID),
the on-disk filename is not significant to ADFFS; for multi-disc sets only the
trailing floppy-number digit matters.

The `JFDI` tag and field layout above come from MAME's reader; an independent
public spec was not located, so no detection signature is promoted here.

## References

- MAME loader: [`src/lib/formats/jfd_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/jfd_dsk.cpp)
- [JASPP — Game files and formats (forums.jaspp.org.uk)](https://forums.jaspp.org.uk/forum/viewtopic.php?t=178)
- [ADFFS / JFD usage notes (forums.jaspp.org.uk)](https://forums.jaspp.org.uk/forum/viewtopic.php?t=232)
- [ADFFS 2.74 released (stardot.org.uk)](https://stardot.org.uk/forums/viewtopic.php?t=23839)
