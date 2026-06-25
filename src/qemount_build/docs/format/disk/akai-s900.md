---
title: Akai S900 floppy disk image
created: 1986
system: Akai S900 / S950 digital samplers
extensions: [".img"]
aliases: [s900, s950, "Akai S-Series DD disk", "Akai sampler disk"]
related:
  - format/disk/roland-sdisk
  - format/disk/fz1
  - format/disk/esq8
  - format/disk/esq16
---

This is the 3.5-inch floppy format used by the Akai S900 (1986) and its
successor the S950 rack-mount MIDI digital samplers. The disks hold the
sampler's sounds, programs and system data.

MAME's loader (`s900_format`, description "Akai S900 floppy disk image")
decodes the media as a fixed-geometry MFM image with no header or magic,
identified by size. It supports two geometries:

- **800 KB DS/DD** (S900 and S950): 80 cylinders, 2 heads, 5 sectors per
  track of 1024 bytes each (80 x 2 x 5 x 1024 = 819,200 bytes).
- **1600 KB DS/HD** (S950 only): 80 cylinders, 2 heads, 10 sectors per
  track of 1024 bytes each.

Both use 1024-byte sectors, which is unusually large for a 3.5-inch
floppy and is one reason the disks cannot be read as ordinary PC media.
The S900 drive writes only the double-density 800 KB layout; the later
S950 adds the high-density 1600 KB variant. MAME's gap timings are noted
as being derived from the uPD7265/uPD72066 floppy-controller datasheets
together with the S900 firmware.

## References

- MAME source: `src/lib/formats/s900_dsk.cpp` (class `s900_format`,
  description "Akai S900 floppy disk image", 800 KB 80/2/5 x 1024 DS/DD
  and 1600 KB 80/2/10 x 1024 DS/HD, MFM).
- ChickenSys Translator, Akai S900/S950 floppy image notes (DS/DD, S950
  DS/HD): http://www.chickensys.com/translator/documentation/floppyimageinfo/akais9x.html
- "How to transfer Akai S900 floppies to PC":
  http://akai-s900.blogspot.com/2008/01/how-to-transfer-floppies-to-pc.html
