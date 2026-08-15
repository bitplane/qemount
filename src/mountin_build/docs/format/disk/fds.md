---
title: FDS (Famicom Disk System image)
created: 1986
system: Nintendo Famicom Disk System
extensions: [".fds"]
aliases:
  - Famicom Disk System image
  - NES disk image
  - fwNES disk format
related:
  - format/disk/raw
---

# FDS (Famicom Disk System image)

A disk image of a Famicom Disk System diskette. The Disk System was a 1986
Japanese peripheral for Nintendo's Family Computer (Famicom) that read
double-sided "Disk Card" quick-disk media, each side holding roughly 64 KB of
game data. The `.fds` format (popularised by the fwNES emulator) stores the
logical contents of those sides — it is not a flux/surface capture but a
reconstruction of the disk's data blocks with the inter-block gaps and CRCs
stripped out.

## Structure

Each disk side is a sequence of typed blocks rather than fixed sectors:

- a **disk information block** (block type 1) identifying the game, maker and
  disk/side numbers;
- a **file-count block** (block type 2) giving the number of files on the side;
- then, for each file, a **file header block** (type 3) describing the file's
  name, address, size and kind, followed by a **file data block** (type 4)
  carrying the bytes.

A raw dump of one side is exactly 65,500 bytes (the data with gaps and CRCs
omitted, zero-padded to length). Images of one, two or four sides therefore run
65,500 / 131,000 / 262,000 bytes. An optional 16-byte header may be prepended,
giving the headered sizes 65,516 / 131,016 / 262,016 bytes; it begins with the
ASCII tag `FDS` plus an end-of-file byte and records the side count.

MAME's loader is a thin recogniser — it validates the size and the `FDS` header
tag and leaves block decoding to the Famicom Disk System emulation. The file is
structured (typed blocks, file directory) and decodes to logical disk content,
so it sits under `disk/`.

## Detection

MAME and the NESdev community documentation agree that a headered image starts
with the four bytes `FDS` followed by `0x1A` (ASCII `"FDS"` plus the DOS
end-of-file marker) at offset 0, with the next byte giving the number of disk
sides. Headerless images carry no signature and are recognised by their exact
multiple-of-65,500 size.

## References

- MAME loader: [`src/lib/formats/nes_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/nes_dsk.cpp)
  — "NES floppy disk image", `.fds`; checks `FDS` tag and the 65,500/65,516-byte
  side sizes.
- [FDS disk format — NESdev Wiki](https://www.nesdev.org/wiki/FDS_disk_format)
  — block types 1–4, 65,500-byte side, no gaps/CRCs.
- [FDS file format — NESdev Wiki](https://www.nesdev.org/wiki/FDS_file_format)
  — the 16-byte `FDS\x1a` header and side count.
</content>
