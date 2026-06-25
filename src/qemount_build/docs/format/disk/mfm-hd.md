---
title: MAME MFM Hard Disk Image
created: 2015
system: MAME emulated ST-506 / MFM hard drives
extensions: []
aliases: [mfm_hd, "MFM hard disk", "ST-506 MFM image"]
related:
  - format/disk/chd
  - format/disk/hxcmfm
  - format/disk/mfi
---

This is MAME's low-level representation of an MFM (Modified Frequency Modulation)
hard disk — the kind of drive driven by an ST-506/ST-412 controller on early PCs
and workstations. It is not a free-standing file with its own extension; the
surface data and geometry live inside a CHD container, and this loader
reconstructs full MFM track bitstreams from the stored sectors on load and writes
the sectors back out on save, auto-detecting the layout parameters.

Because it models the bit-level track surface rather than just a logical sector
array, it falls in the same family as the flux/surface floppy formats: its
navigable structure is the MFM track encoding itself. Each track is built from the
standard MFM run — Gap1, sync, an index/ID address mark, the sector header, CRC,
Gap2, sync, a data address mark, the data field, CRC and Gap3 — with configurable
cylinders, heads, sectors per track, interleave and cylinder/head skew.

Address marks use the usual MFM `A1` sync byte with suppressed clock bits
(`0x4489` at the bit level), the data address mark is `0xFB`, and the sector
header carries an identifier byte, cylinder, head and sector (a PC-AT-style
4-byte header, or a 5-byte custom header that adds a sector-size code). The
identifier byte also extends the cylinder range past 255 (`0xFE`/`0xFF`/`0xFC`/
`0xFD` selecting successive 256-cylinder bands). There is no whole-file magic
signature; identification comes from the CHD hard-disk metadata, so no Detection
section is given here.

The CHD container that holds this data is documented separately. The loader was
contributed to MAME by Michael Zapf.

## References

- MAME source: `src/lib/formats/mfm_hd.cpp` and `mfm_hd.h`
  (https://github.com/mamedev/mame/blob/master/src/lib/formats/mfm_hd.cpp)
- MAME chdman / CHD documentation
  (https://docs.mamedev.org/tools/chdman.html)
