---
title: UniFLEX disk image
created: 1980
system: Motorola 6809 / 680x0 (UniFLEX operating system)
extensions: [".dsk"]
aliases:
  - UniFLEX
related:
  - format/disk/flex
---

# UniFLEX disk image

UniFLEX is a multi-user, multitasking, Unix-like operating system written by
Technical Systems Consultants (TSC) of West Lafayette, Indiana, first released
around 1980 for DMA-capable Motorola 6809 systems (and later ported to the
680x0). It is the multi-user sibling of TSC's single-user
[FLEX](flex.md) — same vendor, but a quite different, Unix-influenced on-disk
structure. This format is the floppy-disk image of a UniFLEX-formatted volume.

Unlike FLEX, which uses 256-byte sectors and a linked-list directory, UniFLEX
uses **512-byte sectors** and a Unix-style layout. MAME's loader recognises 8"
floppy geometries of 77 tracks with 16 sectors per track, single- or
double-sided, in FM or MFM (double-density) encoding.

There is no magic string at the start of the file. Instead the format is
identified structurally by the **System Information Record (SIR)**, a metadata
sector located at byte offset 0x200 (the second 512-byte sector, immediately
after the boot sector). MAME validates an image by checking that the first eight
bytes of the SIR are zero and that its density/side flags and block-count fields
are consistent with the disk's physical geometry. The SIR carries the disk's
parameters (maximum track and sector counts, free-space bookkeeping, and so on),
and is followed by the file-descriptor-node (FDN) area, then the volume data and
swap space.

## References

- MAME loader: [`src/lib/formats/uniflex_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/uniflex_dsk.cpp)
- [UniFLEX — Wikipedia](https://en.wikipedia.org/wiki/UniFLEX)
- [UniFLEX/6809 — Roug retrocomputing](https://www.roug.org/retrocomputing/os/uniflex)
- [The Missing 6809 UniFLEX Archive](http://retro.co.za/6809/UniFLEX/index.html)
