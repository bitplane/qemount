---
title: VTech VZ / Laser floppy disk image
created: 1983
system: VTech Laser 200/210/310, Dick Smith VZ-200/VZ-300
extensions: [".dsk", ".dvz", ".bin"]
aliases:
  - VZ-200 disk image
  - VZ-300 disk image
  - Laser 200 disk image
  - vtech dsk
related:
  - format/fs/vtech
  - format/media/vt-cas
  - format/disk/raw
---

# VTech VZ / Laser floppy disk image

The floppy-disk image format for VTech's optional 5.25-inch disk system, used by
the Laser 200/210/310 and the rebadged Dick Smith VZ-200/VZ-300. The plug-in
controller is a minimal port-mapped device with no on-board formatting logic, so
the recording scheme below is defined entirely by VZ-DOS in software. The disk's
on-media filesystem (the VZ-DOS directory and sector chains) is documented
separately under [`fs/vtech`](../fs/vtech.md); this page covers the image/disk
encoding itself.

## Geometry and encoding

Disks are **single-sided, 40 tracks, 16 sectors per track**, with **128 bytes of
data per sector** — 40 × 16 × 128 = 80 KB of user data. The recording uses a
custom bit encoding (a GCR-like timing scheme) rather than plain FM/MFM IBM
sectors: MAME synthesises each sector from a sync/address-mark preamble, the
track and sector identifiers, the 128 data bytes and a 16-bit little-endian
checksum, and applies a fixed logical-to-physical sector interleave. The
physical sectors carry an inverted-leader preamble (the address and data marks
share a common 0x80-run leader followed by distinct mark sequences), but these
marks are documented only by the MAME decoder, so no detection rule is given
here.

## Image variants

MAME registers two on-disk representations:

- **`.bin` raw image** — a flat dump of all sectors. MAME's raw container uses
  256-byte physical sectors, giving a 163,840-byte (160 KB) file, of which the
  first 128 bytes of each sector are the VZ-DOS data payload.
- **`.dsk` / `.dvz` encoded image** — the community emulator formats, typically
  80 KB, holding the 128-byte data sectors as used by VZ-DOS. Note that several
  mutually incompatible community variants of these extensions exist (early and
  late VZEM `.dsk`, and the DSVZ200/WINVZ300 `.dvz`), so the extension alone does
  not fix the byte layout.

## References

- MAME source: [`src/lib/formats/vt_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/vt_dsk.cpp)
- MAME machine: [Laser/VZ Floppy Disk Controller (`vtech_fdc`)](https://arcade.vastheman.com/minimaws/machine/vtech_fdc)
- [VTech Laser 200 — Wikipedia](https://en.wikipedia.org/wiki/VTech_Laser_200)
- [KryoFlux forum — VZ200/VZ300 5.25" floppy format](https://forum.kryoflux.com/viewtopic.php?t=63)
- [The Dick Smith VZ-200 / VZ-300 computer — vz200.org](http://www.vz200.org/bushy/history.htm)
