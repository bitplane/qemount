---
title: Roland S-Disk image
created: 1986
system: Roland S-series samplers (S-50 / S-330 / S-550 / W-30)
extensions: [".out", ".w30"]
aliases: [roland_sdisk, "Roland S-Disk", "Roland sampler disk"]
related:
  - format/disk/akai-s900
  - format/disk/fz1
  - format/disk/esq8
  - format/disk/esq16
  - format/disk/ppg-waveterm
---

The Roland S-Disk format is the floppy layout used by Roland's first
generation of rack and keyboard digital samplers: the S-50 (1986), the
S-330 and S-550 rack units, and the W-30 sampling workstation. These
machines store their sound libraries, patches and operating system on
3.5-inch double-sided double-density (DSDD) diskettes.

MAME's loader (`roland_sdisk_format`, registered as `roland_sdisk`,
description "Roland S-Disk image") treats the media as a plain
fixed-geometry MFM image and decodes it through the generic WD177x
controller helper. The single geometry it describes is 80 cylinders,
2 heads, 9 sectors per track of 512 bytes each, i.e. a standard 720 KB
3.5-inch DSDD layout written in MFM. There is no header or magic; the
image is a raw sector dump and is identified by extension and size only.

The loader registers two extensions, `.out` and `.w30`. The `.w30`
extension reflects images dumped from W-30 workstation disks; tools and
archives in the Roland sampler community circulate these images alongside
the related S-50/S-330/S-550 disks, which share the same low-level
recording format even though their on-disk data structures differ from
the later S-7xx generation.

The MAME source carries a TODO noting that the high-density format used by
the newer S-750/S-760/S-770 samplers is not yet handled, so this loader
covers only the early DSDD family.

## References

- MAME source: `src/lib/formats/roland_dsk.cpp` (class `roland_sdisk_format`,
  description "Roland S-Disk image", extensions `out,w30`, geometry
  80/2/9 x 512 MFM DSDD).
- Llama Music, "Roland S-50 / S-550 / S-330 / W-30" sampler resource and
  OmniFlop notes: https://llamamusic.com/s50s550/omniflop.html
- Llama Music, Roland S-series disk/format information:
  https://llamamusic.com/s50s550/sinfo.html
