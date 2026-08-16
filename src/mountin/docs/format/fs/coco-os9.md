---
title: OS-9 RBF filesystem (CoCo)
created: 1980
system: Tandy/TRS-80 Color Computer (CoCo) running OS-9
extensions: [".dsk", ".os9"]
aliases:
  - OS-9 RBF
  - OS-9 Level Two filesystem
  - RBF (Random Block File Manager)
  - NitrOS-9 filesystem
related:
  - format/fs/coco-rsdos
  - format/disk/coco-rawdsk
  - format/disk/jvc
  - format/disk/dmk
---

# OS-9 RBF filesystem (CoCo)

OS-9 is Microware's 6809 real-time operating system, which Tandy licensed for
the Color Computer (and which lives on as the community-maintained NitrOS-9).
Its disk storage is managed by the RBF (Random Block File) manager, a
hierarchical, Unix-influenced filesystem — a real directory tree with
pathnames, per-file owner IDs, attributes and timestamps — and is therefore
quite distinct from the flat [RS-DOS / Disk BASIC](coco-rsdos.md) layout that
shares the same physical CoCo floppies. MAME mounts this filesystem on a raw
single-sided 5.25" CoCo image (35 or 40 tracks, 18 sectors of 256 bytes).

## Identification sector (LSN 0)

The filesystem is addressed by Logical Sector Number (LSN). LSN 0 is the disk's
identification sector and holds the volume parameters: total sector count
(24-bit), the track size in sectors, the size of the allocation bitmap, the LSN
of the root directory's file descriptor, the disk ID, a format byte (bit 0 =
sides, bit 1 = density), and the volume name. The allocation bitmap that
follows LSN 0 tracks which sectors are free. There is no magic number; MAME
validates the disk by checking that the recorded sectors-per-track is consistent
with the track size.

## Files and directories

Every file (directories included) is described by a File Descriptor (FD) sector
giving the owner ID, attributes, dates, size, and a segment list mapping the
file's logical bytes onto runs of physical sectors. A directory is just a file
whose contents are a sequence of 32-byte entries: a 29-byte filename (the last
character has its high bit set as a terminator, and a leading zero byte marks an
unused/deleted slot) followed by the 3-byte LSN of that entry's FD sector. Newly
created directories contain the conventional `.` and `..` self/parent entries.
Directories are flagged by the directory bit (`0x80`) in the FD's attribute
byte.

## References

- MAME loader: [`src/lib/formats/fs_coco_os9.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/fs_coco_os9.cpp)
- [OS-9 Technical Reference — Disk File Organization (icdia.co.uk)](http://www.icdia.co.uk/microware/tech/tech_7.pdf)
- [OS-9 Operating System notes — roug.org](https://www.roug.org/soren/6809/os9sysprog.html)
- [Adding support for formatting CoCo OS-9 file systems — MAME PR #9434](https://github.com/mamedev/mame/pull/9434)
