---
title: Intel ISIS-II filesystem
created: 1976
system: Intel Intellec MDS / Series II development systems
extensions: []
aliases:
  - ISIS
  - ISIS-II
  - Intel Systems Implementation Supervisor
related:
  - format/fs/cpm
  - format/disk/imd
---

# Intel ISIS-II filesystem

ISIS-II (Intel Systems Implementation Supervisor) was the floppy-disk operating
system for Intel's Intellec MDS and Series II microprocessor development
systems, in use from the late 1970s. Its on-disk filesystem stores a single
flat directory per diskette (no subdirectories) and is built around a small set
of reserved system files placed at fixed locations.

## Structure

The medium is the standard Intel 8-inch floppy: single-sided FM single-density
(~250 KB) or double-density MMFM (~500 KB), with 128-byte sectors. The
filesystem is defined entirely by reserved files at known track/sector
positions rather than by a header or magic number:

- **ISIS.T0** — bootstrap, starting at track 0, sector 1.
- **ISIS.LAB** — volume label / OS version string.
- **ISIS.DIR** — the directory.
- **ISIS.MAP** — the free-space allocation bitmap.

Each directory entry is 16 bytes: a first byte giving allocation state
(in-use / empty / deleted), a 6.3 file name (six-character name plus optional
three-character extension, uppercase letters and digits only), an attribute
byte (format / write-protect / system / invisible), the count of bytes used in
the last sector, the file length in sectors, and a pointer to the file's first
linkage block.

File contents are not contiguous: each file is a chain of **linkage blocks**,
where a linkage block holds backward and forward chain pointers followed by a
list of pointers to the file's data sectors. This lets a file span the disk
freely. The reserved files (ISIS.DIR, ISIS.MAP, ISIS.LAB, ISIS.T0) are
protected from ordinary creation or modification.

There is no magic signature; an ISIS-II volume is identified by the presence of
its system files at their fixed locations.

## References

- MAME loader: [`src/lib/formats/fs_isis.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/fs_isis.cpp)
- [ISIS (operating system) — Wikipedia](https://en.wikipedia.org/wiki/ISIS_(operating_system))
- [Intel "ISIS internals" (bitsavers via archive.org)](https://archive.org/stream/bitsavers_intelISISI_10578889/ISIS_internals_djvu.txt)
- [brouhaha/isisutils — ISIS disk image tools](https://github.com/brouhaha/isisutils/blob/master/isis.py)
