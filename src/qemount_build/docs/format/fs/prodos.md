---
title: Apple ProDOS filesystem
created: 1983
system: Apple II (and Apple IIgs)
extensions: [".po", ".dsk", ".hdv", ".2mg"]
aliases:
  - ProDOS
  - Professional Disk Operating System
  - SOS filesystem
related:
  - format/disk/apple2
  - format/disk/apple-gcr
  - format/fs/hfs
  - format/arc/nufx
---

# Apple ProDOS filesystem

ProDOS (Professional Disk Operating System) is the block-structured filesystem
Apple introduced in 1983 for the Apple II family, succeeding the earlier
track/sector DOS 3.3. It descends from the Apple III's SOS filesystem and is
also used (alongside HFS) on the Apple IIgs. This doc covers the **filesystem
layer** — the volume directory, block allocation, and file structure — as
distinct from the Apple II disk-image containers (`format/disk/apple2`,
`format/disk/apple-gcr`) that merely carry it, and from the NuFX/ShrinkIt
archive format (`format/arc/nufx`).

## Structure

ProDOS addresses storage as 512-byte logical blocks, supporting volumes up to
32 MB (65,536 blocks). The first blocks are reserved:

- **Block 0** — boot loader; **block 1** — reserved (SOS boot, usually empty).
- **Block 2** — start of the **volume directory**, normally four blocks long
  (blocks 2–5). Its header gives the volume name (up to 15 characters, length
  encoded in the high nibble of a type byte), creation date/time, ProDOS
  version fields, the active file count, a pointer to the volume bitmap, and the
  total block count.
- **Block 6** — start of the **volume bitmap**, one bit per block (1 = free).

Directories are chains of 512-byte blocks linked by backward/forward pointers;
each block holds a header plus up to thirteen 39-byte entries. An entry stores a
storage-type/name-length byte, the file name, an 8-bit file type, the key-block
pointer, the block count, a 24-bit length, creation and modification timestamps,
ProDOS version fields, and an aux-type/load-address word.

Files come in three sizes keyed by storage type:

- **Seedling** (≤512 bytes) — the key block *is* the data.
- **Sapling** (≤128 KB) — the key block is an index block of up to 256 data-block
  pointers.
- **Tree** (>128 KB) — the key block is a master index of up to 128 index
  blocks.

A fourth **extended** storage type stores a file with separate data and resource
forks (used on the IIgs), each fork described by its own mini-entry within the
key block. Directories themselves use storage types for subdirectory and volume
headers. ProDOS file types are a 1-byte code space (e.g. TXT `0x04`, BIN `0x06`,
DIR `0x0f`, BAS `0xfc`, SYS `0xff`).

ProDOS has no fixed magic at offset 0 (block 0 is 6502 boot code); a volume is
identified structurally from the volume-directory header at block 2.

## References

- MAME loader: [`src/lib/formats/fs_prodos.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/fs_prodos.cpp)
- [ProDOS filesystem notes — CiderPress II](https://ciderpress2.com/formatdoc/ProDOS-notes.html)
- [ProDOS 8 Technical Reference — file organization (prodos8.com)](https://prodos8.com/docs/techref/file-organization/)
- [ProDOS file system — Just Solve the File Format Problem](http://justsolve.archiveteam.org/wiki/ProDOS_file_system)
