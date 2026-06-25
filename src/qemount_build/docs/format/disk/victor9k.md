---
title: Victor 9000 / Sirius 1 GCR disk image
created: 1982
system: Victor 9000 (Sirius 1)
extensions: [".img"]
aliases:
  - Sirius 1
  - Victor 9k
  - ACT Sirius 1
  - Sirius v9k
related:
  - format/disk/g64
  - format/disk/apple-gcr
---

# Victor 9000 / Sirius 1 GCR disk image

A sector dump of the 5.25-inch floppies used by the Victor 9000, the 1982
personal computer designed by Chuck Peddle's team at Victor / Sirius Systems
Technology and sold in Europe as the ACT Sirius 1. The machine is notable for an
unusually dense, technically ambitious disk scheme that squeezed far more data
onto a standard 5.25-inch diskette than its contemporaries.

## Encoding and geometry

The Victor 9000 records in **group coded recording (GCR)**, the same 4-bit-to-
5-bit (nibble-to-5-bit) translation used by Commodore's 1541, mapping each data
nibble to a 5-bit run-length-limited code. Like Commodore's drives it uses a
form of **zoned recording**: the disk is divided into speed zones, and the drive
spins faster on inner tracks and slower on outer ones so that the linear bit
density stays roughly constant across the surface (an approximation of constant
linear velocity, sometimes called ZCLV). MAME and FluxEngine describe **nine
speed zones** selected from the fifteen the hardware supports, with rotational
speeds ranging from about **252 RPM** in the slowest outer zone to **417 RPM**
in the fastest inner zone.

Because each zone packs a different number of sectors, sectors-per-track varies
from **19 on the outermost zone down to 11/12 on the innermost**, across **80
tracks per side**. Sectors hold **512 bytes** of data. Single-sided disks carry
1224 sectors (~600 KB) and double-sided disks 2391 sectors (~1.2 MB) — an
enormous capacity for a 5.25-inch diskette in 1982. The two sides are addressed
as one logical track range (0–79 on the first surface, 80–159 on the second).

The on-disk image is a straight ordered dump of those decoded sectors; the
variable-speed flux structure is reconstructed from the geometry when the image
is written back to a flux representation. The boot/system sector at track 0
carries a load header (load address, entry point, disc ID and the per-zone speed
table), but this is filesystem/loader metadata rather than an image signature,
and there is no portable magic number that reliably marks the raw image, so no
detection rule is given here.

## References

- MAME source: [`src/lib/formats/victor9k_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/victor9k_dsk.cpp)
- [FluxEngine — Victor 9000 disk format](https://cowlark.com/fluxengine/doc/disk-victor9k.html)
- [Applesauce wiki — Sirius / Victor 9000 (v9k)](https://wiki.applesaucefdc.com/doku.php?id=platforms:sirius_v9k)
- [DiscFerret wiki — Victor 9000 format](https://discferret.com/wiki/Victor_9000_format)
- [Victor 9000 / Sirius Systems Technology — Wikipedia](https://en.wikipedia.org/wiki/Victor_9000)
