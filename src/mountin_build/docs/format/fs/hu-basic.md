---
title: Hu-BASIC filesystem (Sharp X1)
created: 1982
system: Sharp X1 (Hudson Soft Hu-BASIC)
aliases:
  - Hudson BASIC disk
  - Hu-BASIC DOS
  - S-OS / Hu-BASIC X1 disk
related:
  - format/disk/2d
  - format/disk/d88
  - format/disk/raw
detect:
  all:
    # Allocation table (sector 14, offset 0xE00): cluster 0 = boot (chains to 1),
    # cluster 1 = root directory (terminal + full). Invariant on every 2D disk.
    - offset: 0xE00
      type: string
      value: [0x01, 0x8f]
    # Clusters 80-127 do not exist on an 80-cluster 2D disk; the formatter fences
    # them off as 0x8f and nothing ever touches them. 48 fixed bytes at 0xE50.
    - offset: 0xE50
      type: string
      value: [0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f]
---

# Hu-BASIC filesystem (Sharp X1)

The on-disk filesystem written by **Hu-BASIC**, the disk BASIC / disk operating
system that Hudson Soft supplied for the Sharp X1 (and used more widely across
Sharp's early 8-bit machines). It is the filesystem that lives *inside* the raw
sector images of X1 floppies, so it is the layer that actually makes the files
on a [`disk/2d`](../disk/2d) or [`disk/d88`](../disk/d88) image readable — the
disk-image formats are just the container; Hu-BASIC is the directory and
allocation structure within.

Multi-byte fields are little-endian. The reference open-source implementation is
**HuDisk** by BouKiCHi, which reads and writes these images.

## Layout

| Property | Value |
|----------|-------|
| Sector size | 256 bytes |
| Directory entry | 32 bytes (8 per 256-byte sector) |
| Allocation | FAT-style cluster chain |
| Reserved | Clusters 0–1 (boot, allocation table, root directory) |
| Disk types | 2D (default), 2DD, 2HD |

Clusters are laid down alternating between the two sides of the disk: the
least-significant bit of a cluster number selects the head and the upper bits
select the cylinder, so consecutive clusters ping-pong across head 0 and head 1
of the same cylinder.

## Directory entry (32 bytes)

| Field | Size | Notes |
|-------|------|-------|
| File mode | 1 | attribute byte (see below); `0x00` = deleted entry, `0xFF` = end of directory |
| Filename | 13 | space-padded |
| Extension | 3 | space-padded |
| Password | 1 | `0x20` when unused |
| File size | 2 | bytes |
| Load address | 2 | for binary files |
| Execute address | 2 | for binary files |
| Date/time | 6 | BCD: year, month+weekday, day, hour, minute, second |
| Start cluster | 2 | first cluster of the file's chain |

### File mode (attribute) byte

Per the Hu-BASIC implementation, the bits are:

| Bit | Meaning |
|-----|---------|
| 7 | Directory |
| 6 | Read-only |
| 5 | Verify (uncertain) |
| 4 | Hidden |
| 2 | ASCII |
| 1 | BASIC program |
| 0 | Binary |

A type is resolved by precedence: binary (bit 0) wins, then BASIC (bit 1), then
ASCII. Binary files carry meaningful load and execute addresses; ASCII files are
stored with `0x0D` line endings and a `0x1A` end-of-file marker.

## Allocation table

Files are chains of clusters recorded in a FAT-like allocation table (in the
reserved area). A free cluster reads as `0x00`. The terminal cluster of a chain
is flagged with the high bit set, and its low nibble gives the number of sectors
actually used in that last cluster (so file length is exact to the sector, with
the byte count taken from the directory entry). A cluster is a fixed run of
sectors; clusters per disk depend on the 2D/2DD/2HD geometry.

## Identification

Hu-BASIC has no superblock signature at a fixed offset, so it is recognised
**structurally** from its allocation table (sector 14, offset `0xE00`):

- cluster 0 (boot) and cluster 1 (root directory) are always reserved, so the
  first two table bytes are `01 8f`;
- clusters 80–127 do not exist on an 80-cluster 2D disk, so the formatter fences
  them off — table bytes `0x50`–`0x7F` (file offset `0xE50`) are 48 bytes of
  `0x8f` that nothing ever changes.

The `detect:` rule keys on these two invariants. It is 2D-specific; 2DD and 2HD
use a larger cluster count and a two-sector table, so they fence a different
region and would need their own `any:` branches.

## References

- [HuDisk — X1 Hu-BASIC disk image handler (BouKiCHi)](https://github.com/BouKiCHi/HuDisk)
  — reference reader/writer; `HuFileEntry.cs` / `HuBasicDiskEntry.cs` define the
  32-byte entry, the file-mode bits, and the cluster-chain allocation
- [Sharp X1 Notes — engineers@work](https://eaw.app/sharpx1-notes/)
- [Sharp X1 Specifications — engineers@work](https://eaw.app/sharpx1-specifications/)
- [Sharp X1 — Wikipedia](https://en.wikipedia.org/wiki/Sharp_X1)
