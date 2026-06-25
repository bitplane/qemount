---
title: Oric Jasmin filesystem
created: 1984
system: Oric (Oric-1 / Atmos) with Jasmin disc interface
extensions: [".dsk"]
aliases:
  - Jasmin
  - Jasmin DOS
  - FT-DOS
related:
  - format/fs/sedoric
  - format/disk/raw
---

# Oric Jasmin filesystem

The Jasmin was one of several floppy-disc interfaces for the Oric-1 and Oric
Atmos home computers, built around a Western Digital WD1773 controller and
running its own disc operating system (FT-DOS). This is the on-disk filesystem
that Jasmin/FT-DOS uses — a flat, single-directory layout with no
subdirectories.

## Structure

Disks are the usual Oric geometry: 41 tracks, 17 sectors per track, 256 bytes
per sector, single- or double-sided (~178 KB or ~357 KB). The filesystem keeps
its metadata on a central directory track, track 20 (`0x14`) — a convention
shared with other Oric DOSes such as SEDORIC, which also places its bitmap on
track 20.

Per MAME's reader, the layout is:

- **Volume / bitmap sector** (track 20, sector 1). Holds an 8-character,
  space-padded volume name, a 16-bit signature word (`0x8080` in MAME's
  implementation), track/sector references, and a free-space bitmap with one
  24-bit entry per track.
- **Directory** (track 20, sector 2 onward). Each directory sector begins with
  its own and the next directory sector's references, then up to fourteen
  18-byte file entries. An entry records the first inode sector, a lock flag
  (`U`/`L`), an 8.3 file name, a file type (`S`equential or `D`irect), and a
  16-bit sector count.
- **Inodes.** Each file is described by a chain of inode sectors. The first
  inode sector carries the load address and the file length in bytes; every
  inode sector then lists references to the file's data sectors, with `0xff00`
  marking the end of the chain.

The 16-bit `0x8080` signature comes from MAME's loader and is not corroborated
by an independent second source, so it is not promoted to a detection rule here.
The broader layout — a flat catalogue and bitmap on a dedicated central track —
is consistent with independently documented Oric disc structure.

## References

- MAME loader: [`src/lib/formats/fs_oric_jasmin.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/fs_oric_jasmin.cpp)
- [Kenneth Bernholm — The Oric Microdisc / disc controllers](https://zrk.dk/the-oric-microcomputer/microdisc/)
- [SEDORIC DOS notes (oric.free.fr) — track-20 metadata convention](http://oric.free.fr/DISKS/sedoric.html)
- [DSK (Oric) — Just Solve the File Format Problem](http://justsolve.archiveteam.org/wiki/DSK_(Oric))
