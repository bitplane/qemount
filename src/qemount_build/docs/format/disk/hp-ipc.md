---
title: HP Integral PC floppy image
created: 1985
system: HP Integral PC (HP 9807A)
extensions: [".img"]
aliases:
  - HP IPC disk image
  - HP 9807 floppy
related:
  - format/fs/hp-lif
  - format/disk/hp300
  - format/disk/hpi
---

# HP Integral PC floppy image

This is a raw sector image of a 3.5" floppy disk as used by the HP Integral PC
(model HP 9807A), a "luggable" Motorola 68000 workstation released in 1985 that
ran HP-UX from ROM. The machine had a single built-in 3.5" drive holding around
710 KB per disc.

## Structure

The file is a headerless dump of every sector in cylinder/head/sector order — no
magic number, no container. MAME's loader, built on the Western Digital
WD177x format helper, describes a single geometry: 3.5" double-sided
double-density, MFM, 77 cylinders, 2 heads, 9 sectors per track, 512-byte
sectors (a 2 Mbit/s data rate). A source comment notes the reference images came
from coho.org and that the inter-sector gap values are unverified, so treat the
exact gap layout as approximate.

There is no signature, so no signature-based detection is defined here; HP
Integral discs carry an HP LIF volume (`format/fs/hp-lif`).

## References

- MAME loader: [`src/lib/formats/hp_ipc_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/hp_ipc_dsk.cpp)
- [HP Integral PC — Wikipedia](https://en.wikipedia.org/wiki/HP_Integral_PC)
- [HP 9807A Integral UNIX Portable Computer — Computer History Museum](https://www.computerhistory.org/collections/catalog/102638231)
- [Driver:HP IPC — MAMEDEV Wiki](https://wiki.mamedev.org/index.php/Driver:HP_IPC)
