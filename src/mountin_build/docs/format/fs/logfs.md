---
title: LogFS
created: 2009
discontinued: 2016
related:
  - format/fs/jffs2
  - format/fs/ubifs
  - format/fs/f2fs
detect:
  - offset: 0x18
    type: be64
    value: 0x7a3a8e5cb9d5bf67
---

# LogFS

LogFS was a log-structured filesystem for flash storage (MTD/block devices)
developed by Jörn Engel. It was merged into the Linux kernel in version
2.6.34 (May 2010) and removed in version 4.6 (May 2016) due to lack of
maintenance. It was superseded by F2FS and UBIFS for flash storage use cases.

## Characteristics

- Log-structured design optimised for flash/SSD
- 4KB block size (fixed)
- B-tree based metadata
- Garbage collection with level-based segment separation
- Up to 5 levels of indirect blocks (16 direct pointers + 1 indirect)
- Journal-based crash recovery (16 journal segments)
- CRC32 checksums on segment headers
- Support for MTD (raw flash) and block devices
- Embedded small files in inode (up to 136 bytes)

## Disk Layout

The superblock is stored at the beginning of the device (offset 0 for block
devices). A backup copy is stored at the last aligned 4KB block. The
filesystem is divided into segments, each with a segment header.

### Superblock

The superblock begins with a segment header followed by the disk super
structure. All multi-byte fields are big-endian.

| Offset | Size | Field                | Description                     |
|--------|------|----------------------|---------------------------------|
| 0x00   | 4    | crc                  | CRC32 of segment header         |
| 0x04   | 2    | pad                  | Must be 0                       |
| 0x06   | 1    | type                 | Segment type (0x01 = super)     |
| 0x07   | 1    | level                | GC level                        |
| 0x08   | 4    | segno                | Segment number                  |
| 0x0C   | 4    | ec                   | Erase count                     |
| 0x10   | 8    | gec                  | Global erase count              |
| 0x18   | 8    | ds_magic             | Magic: 0x7a3a8e5cb9d5bf67       |
| 0x20   | 4    | ds_crc               | CRC32 of super (from next field)|
| 0x24   | 1    | ds_ifile_levels      | Max ifile indirection levels    |
| 0x25   | 1    | ds_iblock_levels     | Max file indirection levels     |
| 0x26   | 1    | ds_data_levels       | Number of data level separations|
| 0x27   | 1    | ds_segment_shift     | log2(segment size)              |
| 0x28   | 1    | ds_block_shift       | log2(block size), typically 12  |
| 0x29   | 1    | ds_write_shift       | log2(write size)                |
| 0x2A   | 6    | pad                  | Reserved                        |
| 0x30   | 8    | ds_filesystem_size   | Total filesystem size in bytes  |
| 0x38   | 4    | ds_segment_size      | Segment size in bytes           |
| 0x3C   | 4    | ds_bad_seg_reserve   | Reserved segments for bad blocks|
| 0x40   | 8    | ds_feature_incompat  | Incompatible feature flags      |
| 0x48   | 8    | ds_feature_ro_compat | Read-only compatible features   |
| 0x50   | 8    | ds_feature_compat    | Compatible feature flags        |
| 0x58   | 8    | ds_feature_flags     | Filesystem flags                |
| 0x60   | 8    | ds_root_reserve      | Bytes reserved for superuser    |
| 0x68   | 8    | ds_speed_reserve     | Bytes reserved for GC speed     |
| 0x70   | 64   | ds_journal_seg       | Journal segment numbers (16x4B) |
| 0xB0   | 16   | ds_super_ofs         | Superblock offsets (2x8B)       |

## Detection

Magic number `0x7a3a8e5cb9d5bf67` (big-endian 64-bit) at offset 0x18. The
32-bit statfs magic is `0xc97e8168`.

## Guest Support

LogFS was in the Linux kernel from 2.6.34 to 4.6. Mounting requires a kernel
within that range. The `mklogfs` tool from the logfs-progs package creates
LogFS filesystems.
