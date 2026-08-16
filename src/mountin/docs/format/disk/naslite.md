---
title: NASLite (1.72 MB NAS boot floppy image)
created: early 2000s
system: IBM PC compatible (x86); NASLite NAS server OS
extensions: [".img"]
aliases:
  - NASLite disk image
  - NASLite 1.72MB floppy
related:
  - format/disk/raw
---

# NASLite (1.72 MB NAS boot floppy image)

A raw sector image of the single floppy that boots NASLite, a tiny Linux-based
network-attached-storage operating system from Server Elements. NASLite v1
(early 2000s) turned a commodity x86 PC into an SMB/CIFS, NFS or FTP file server,
booting entirely from one 3.5" high-density floppy that had been over-formatted
to 1.72 MB so as to fit the kernel and tools. In MAME the format is attached to
generic IBM-PC-compatible floppy controllers (it is registered by x86 machines
and ISA/super-I/O FDC devices), not to any specific game system.

The image is a flat dump of every sector with no header or magic; it is
distinguished from an ordinary PC floppy image by its extended geometry and an
unusual sector interleave (MAME's own comment calls it the "funky interleaving"
format).

## Geometry

MFM encoding, identified by the 1.72 MB total size:

| Property | Value |
|----------|-------|
| Tracks (cylinders) | 82 |
| Heads (sides) | 2 |
| Sectors / track | 21 |
| Bytes / sector | 512 |
| Total | 82 × 2 × 21 × 512 = 1,763,328 bytes (1.72 MB) |

Rather than laying sectors down in plain ascending order, the format assigns each
logical sector an ID computed from its position — MAME derives the physical
sector index as `(i + track × 0x0a + head × 0x11) mod 21` — so the on-disk order
is skewed per track and per head. This interleave is the only thing that makes
the image more than a bare size-matched blob, and is why the geometry alone is
insufficient to round-trip the disk faithfully.

## References

- MAME loader: [`src/lib/formats/naslite_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/naslite_dsk.cpp)
  — "NASLite 1.72MB with funky interleaving format", 82/2/21/512, custom sector
  ID interleave; registered by x86/ISA FDC drivers (e.g. `ampro/lb186.cpp`,
  `olivetti/m24.cpp`).
- [NASLite — Wikipedia](https://en.wikipedia.org/wiki/NASLite) — single-floppy
  Linux NAS OS that fits on a 3.5" HD floppy formatted to 1.72 MB.
- [NASLite-NFS/NFSG User Manual — Server Elements](https://www.serverelements.com/bin/NASLite-NFS_and_NASLite-NFSG_User_Manual_r1.0_08-2004.pdf)
  — official documentation of the 1.72 MB floppy distribution.
</content>
