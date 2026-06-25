---
title: Tandy 2000 floppy image
created: 1983
system: Tandy 2000 (Intel 80186, MS-DOS)
extensions: [".dsk"]
aliases: [tandy2k, "Tandy 2000 DSK", "TRS-80 Model 2000 disk"]
related:
  - format/disk/pc-img
---

# Tandy 2000 floppy image

A raw, headerless sector image of a floppy disk from the Tandy 2000, the
Radio Shack desktop launched in November 1983 around an 8 MHz Intel 80186
running MS-DOS. The machine was pitched as a faster, higher-capacity IBM PC
alternative, but its quad-density drives and non-CGA graphics made it largely
incompatible with mainstream PC software, and it sold poorly.

Where the IBM PC of the day shipped 360 KB double-density 5.25-inch drives, the
Tandy 2000 used **quad-density** 5.25-inch drives formatted to **720 KB**. In
MAME the loader builds on the shared `upd765_format` machinery (the disk is read
through a NEC uPD765-style controller), so the image is just the decoded MFM
sector data laid out in order, with no container header.

## Structure

A single fixed geometry:

- 80 tracks, 2 heads (double-sided)
- 9 sectors per track, 512 bytes per sector
- MFM encoding, 250 kbit/s-class quad-density recording (2000 ns nominal cell)
- 80 × 2 × 9 × 512 = 737,280 bytes (720 KB)

There is no magic number or header: the file is the raw sector payload and is
identified by its size and geometry, not by any signature. MAME's own comment
notes the inter-sector gap values are unverified against original hardware. The
on-disk filesystem is standard MS-DOS FAT, so once the raw image is in hand the
volume is an ordinary FAT12 floppy.

## References

- MAME source: `src/lib/formats/tandy2k_dsk.cpp` and `tandy2k_dsk.h`
  (BSD-3-Clause, Curt Coder) — defines `FLOPPY_TANDY_2000_FORMAT`, 80/2/9/512
  MFM, "720K 5.25 inch quad density".
- Wikipedia, "Tandy 2000" — 80186, MS-DOS, Nov 1983 launch, 80-track
  double-sided quad-density 720 KB drives.
- tandy-trs80.com / Low End Mac — historical background and 720 KB quad-density
  drive details.
