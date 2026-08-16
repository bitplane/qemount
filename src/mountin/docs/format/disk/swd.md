---
title: SWD (Swift Disc)
created: 1987
system: ZX Spectrum 128 (Sixword Swift Disc interface)
extensions: [".swd"]
aliases:
  - Swift Disc disk image
related:
  - format/disk/opd
  - format/disk/scl
  - format/disk/coupe
  - format/disk/raw
---

# SWD (Swift Disc)

A raw sector image for the Swift Disc, a floppy-disc interface for the Sinclair
ZX Spectrum (notably the 128K models) made by Sixword Ltd of the UK around
1987–88. The Swift Disc was a WD1770-based controller card with 8 KB of RAM and
16 KB of ROM, a serial/printer port, a Kempston joystick port and an
"interrupt" button for its command console; it could drive up to four 3.5-inch
or 5.25-inch drives and was marketed as a premium alternative to the Amstrad
Spectrum +3.

The `.swd` image is a flat dump of disk sectors with no header or magic. MAME's
loader builds the track image through the WD177x model from a fixed geometry:

| Drive | Tracks | Sides | Sectors/track | Bytes/sector | Capacity | Encoding |
|-------|--------|-------|---------------|--------------|----------|----------|
| 3.5" | 80 | 2 | 16 | 256 | 640 KB | MFM (DD) |
| 5.25" | 80 | 2 | 16 | 256 | 640 KB | MFM (QD) |

A quirk worth recording: disks formatted by the original interface number their
two sides 1 and 2 rather than the usual 0 and 1, so the loader offsets the head
number when computing where each track lives in the file.

This is a headerless, fixed-geometry sector image, so there is no signature to
match; identification is by extension and disk size.

## References

- MAME loader: [`src/lib/formats/swd_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/swd_dsk.cpp)
  (system wiring in [`src/devices/bus/spectrum/sixword.cpp`](https://github.com/mamedev/mame/blob/master/src/devices/bus/spectrum/sixword.cpp))
- [Swift Disc 2 — Sixword (hardware.speccy.org)](https://hardware.speccy.org/hardware/Swift_Disc2-Sixword.html)
- [Swift Disc — Spectrum Computing](https://spectrumcomputing.co.uk/zxsr.php?id=1000412)
- [Swift Disk hardware feature — World of Spectrum](https://worldofspectrum.org/hardware/feate.html)
