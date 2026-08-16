---
title: FM Towns Floppy Disk Image
created: unknown
system: Fujitsu FM Towns
extensions: [".bin"]
aliases: [fmtowns_dsk, FM Towns disk image]
related:
  - format/disk/d88
---

The FM Towns floppy disk image is a raw, headerless sector dump of a 3.5"
high-density floppy as used by Fujitsu's FM Towns line of Japanese personal
computers and the FM Towns Marty console (the FM Towns launched in 1989). MAME's
loader handles it through the generic Western Digital WD177x sector-image
framework, so the file is simply the concatenated sector data with no metadata,
magic, or per-sector tags.

## Structure

The image describes a single fixed geometry, the Japanese "2HD" 1.2 MB format
that the FM Towns shares with the PC-98 and X68000 lines:

- Form factor: 3.5" high density, MFM encoding
- 77 cylinders (tracks)
- 2 heads (double sided)
- 8 sectors per track
- 1024 bytes per sector

That works out to 77 × 2 × 8 × 1024 = 1,261,568 bytes, i.e. about 1232 KB or the
"1.23 MB" capacity commonly quoted for these disks. Because there is no header,
the file cannot be distinguished from other raw same-size sector dumps by content
alone; identification relies on the surrounding context (extension, software
list) and the known geometry. FM Towns software is also frequently distributed
in the structured D88 container instead, which does carry a header.

## References

- MAME source: `src/lib/formats/fmtowns_dsk.cpp` (and its header), which derives
  from `wd177x_format` and declares the 77/2/8/1024 geometry with gap parameters.
- [Driver:FMTowns — MAMEDEV Wiki](https://wiki.mamedev.org/index.php/Driver:FMTowns)
- [Writing a 1.23MB FM Towns floppy image back to a real disk — YSFLIGHT.com](http://ysflight.in.coocan.jp/FM/towns/writefdimage/e.html)
- [Fujitsu FM Towns floppy disk images (fmtowns_flop_orig) — minimaws software list](https://arcade.vastheman.com/minimaws/softwarelist/fmtowns_flop_orig)
