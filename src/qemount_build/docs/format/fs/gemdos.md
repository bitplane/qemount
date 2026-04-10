---
title: GEMDOS (Atari TOS)
created: 1985
related:
  - format/fs/fat12
  - format/fs/fat16
  - format/pt/atari
detect:
  - offset: 0
    type: checksum
    length: 512
    algorithm: atari_boot
---

# GEMDOS / Atari TOS File System

GEMDOS is the filesystem used by Atari ST/STE/TT/Falcon computers, implemented
in the GEMDOS layer of the TOS (The Operating System) ROM. It is based on
FAT12/FAT16 as defined by MS-DOS, but with several Atari-specific differences
that make it incompatible with standard PC FAT detection.

Introduced in 1985 with the Atari ST, GEMDOS was used on 360KB/720KB floppy
disks and hard drives up to 2GB (with later TOS versions).

## Key Differences from PC FAT

- **Boot signature**: No 0x55AA marker. Instead, the sum of all 256 big-endian
  16-bit words in the boot sector must equal 0x1234
- **Branch instruction**: 68000 BRA.S (0x60xx) at offset 0, not x86 JMP (0xEB)
- **OEM field**: Used as a serial number for floppy change detection
- **Bytes per sector**: Stored as big-endian (PC FAT uses little-endian)
- **Sectors per cluster**: Always 2 (GEMDOS emulates larger sectors instead)
- **Logical sectors**: BPS can be 512, 1024, 2048, 4096, 8192 (vs always 512
  on PC FAT)

## Boot Sector (512 bytes)

| Offset | Size | Field   | Description                              |
|--------|------|---------|------------------------------------------|
| 0x00   | 2    | BRA     | 68000 BRA.S instruction                  |
| 0x02   | 6    | OEM     | Filler / OEM info                        |
| 0x08   | 2    | SERIAL  | Disk serial number (low 24 bits)         |
| 0x0B   | 2    | BPS     | Bytes per sector (big-endian)            |
| 0x0D   | 1    | SPC     | Sectors per cluster (always 2)           |
| 0x0E   | 2    | RES     | Reserved sectors                         |
| 0x10   | 1    | NFATS   | Number of FATs (usually 2)               |
| 0x11   | 2    | NDIRS   | Root directory entries                   |
| 0x13   | 2    | NSECTS  | Total logical sectors                    |
| 0x15   | 1    | MEDIA   | Media descriptor (0xF8 for hard disk)    |
| 0x16   | 2    | SPF     | Sectors per FAT                          |
| 0x18   | 2    | SPT     | Sectors per track (floppy only)          |
| 0x1A   | 2    | NHEADS  | Number of heads (floppy only)            |
| 0x1C   | 2    | NHID    | Hidden sectors                           |
| 0x1E   | var  | BOOT    | Boot code (if bootable)                  |
| 0x1FE  | 2    | CKSUM   | Checksum (included in 0x1234 sum)        |

## Detection

The boot sector checksum: sum all 256 big-endian 16-bit words across the
512-byte sector. If the result equals 0x1234, the sector is a valid Atari
TOS boot sector. This replaces the PC FAT 0x55AA signature.

Note: not all GEMDOS disks are bootable, and non-bootable disks may not have
a valid checksum. The checksum is primarily used for boot detection by the
TOS ROM, and some formatting tools may not set it for data-only disks.

## Partition Layout

On floppy disks, GEMDOS occupies the entire disk (no partition table).
On hard drives, partitions are defined by the Atari root sector (partition
table) at physical sector 0, with partition types:

- **GEM**: Regular partition (< 32MB)
- **BGM**: Big partition (>= 32MB)
- **XGM**: Extended partition

## Characteristics

- FAT12 for floppies (< 4086 clusters)
- FAT16 for hard drives (> 4086 clusters)
- 8.3 filenames (no long filename support in original TOS)
- Maximum partition sizes:
  - TOS < 1.04: 16MB (GEM), 256MB (BGM)
  - TOS >= 1.04: 32MB (GEM), 512MB (BGM)
  - TOS 4.x (Falcon): 32MB (GEM), 2GB (BGM)
- Root directory is fixed size, set at format time
- 32-byte directory entries (same structure as DOS FAT)

## Directory Entry (32 bytes)

| Offset | Size | Field    | Description                            |
|--------|------|----------|----------------------------------------|
| 0x00   | 8    | FNAME    | Filename (space-padded)                |
| 0x08   | 3    | FEXT     | Extension (space-padded)               |
| 0x0B   | 1    | ATTRIB   | File attributes                        |
| 0x0C   | 10   | RES      | Reserved                               |
| 0x16   | 2    | FTIME    | Time (2-second resolution)             |
| 0x18   | 2    | FDATE    | Date (years since 1980)                |
| 0x1A   | 2    | SCLUSTER | Starting cluster                       |
| 0x1C   | 4    | FSIZE    | File size in bytes                     |

## Guest Support

Linux can mount GEMDOS floppies using the standard FAT/VFAT driver with
appropriate options. The Atari partition table is supported via
CONFIG_ATARI_PARTITION. For hard drives with Atari partition tables, Linux's
atari partition handler recognises GEM/BGM/XGM types.
