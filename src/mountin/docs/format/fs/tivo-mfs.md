---
title: TiVo MFS
created: 1999
related:
  - format/fs/ext2
detect:
  any:
    - offset: 0x04
      type: be32
      value: 0xabbafeed
    - offset: 0x04
      type: be32
      value: 0xebbafeed
---

# TiVo Media File System (MFS)

MFS is a proprietary filesystem used by TiVo digital video recorders.
Designed for fault-tolerant real-time recording of live TV, it is organised
more like a database than a traditional filesystem, with transaction logging
and rollback capabilities.

TiVo hard drives use a combination of Apple Partition Map (APM) and multiple
MFS partitions — some for application data (metadata, program guide) and
others for media (recorded video streams).

## Characteristics

- Database-like organisation with FSID (file system ID) per object
- Transaction logging with rollback
- Four object types: Stream, Directory, Database, File
- Stream objects stored in media regions (large, contiguous)
- Other objects in application regions
- Zone map linked lists for space management
- Big-endian (PowerPC/MIPS TiVo hardware)
- 32-bit and 64-bit variants

## Volume Header (sector 0, 512 bytes)

All fields big-endian.

| Offset | Size | Field          | Description                        |
|--------|------|----------------|------------------------------------|
| 0x00   | 4    | state          | Volume state                       |
| 0x04   | 4    | magic          | 0xABBAFEED (32-bit) or 0xEBBAFEED (64-bit) |
| 0x08   | 4    | checksum       | CRC of header                      |
| 0x10   | 4    | root_fsid      | Root filesystem ID                 |
| 0x18   | 4    | firstpartsize  | First partition size / 1024        |
| 0x24   | 128  | partitionlist  | Partition device list (ASCII)      |
| 0xA4   | 4    | total_sectors  | Total sectors in volume            |
| 0xAC   | 4    | logstart       | Log area start sector              |
| 0xB0   | 4    | lognsectors    | Log area size                      |
| 0xB4   | 4    | logstamp       | Log timestamp                      |

A backup copy of the volume header is stored at the last sector of the
first partition.

## Detection

Magic number at offset 0x04 (big-endian 32-bit):
- `0xABBAFEED` — 32-bit MFS (older TiVo models)
- `0xEBBAFEED` — 64-bit MFS (newer TiVo models, Series 3+)

## Zone Maps

Space allocation uses zone maps — linked list structures starting from
the first application zone. Three flavours describe:
- Inode zones
- Application regions (metadata)
- Media regions (video streams)

## Guest Support

TiVo runs a modified Linux kernel on PowerPC (Series 1) or MIPS (Series 2+)
hardware. The MFS filesystem is a kernel module, never open-sourced.
Community tools (mfstools) can read/backup MFS volumes. No standard Linux
kernel support exists.
