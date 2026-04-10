---
title: CMS (VM/CMS)
created: 1965
related:
  - format/fs/cpm
detect:
  any:
    # EDF 4096-byte blocks: label at block 2 = offset 0x2000
    - offset: 0x2000
      type: string
      value: "\xC3\xD4\xE2\xF1"
    # EDF 1024-byte blocks: label at block 2 = offset 0x800
    - offset: 0x800
      type: string
      value: "\xC3\xD4\xE2\xF1"
    # EDF 2048-byte blocks: label at block 2 = offset 0x1000
    - offset: 0x1000
      type: string
      value: "\xC3\xD4\xE2\xF1"
    # EDF 512-byte blocks: label at block 2 = offset 0x400
    - offset: 0x400
      type: string
      value: "\xC3\xD4\xE2\xF1"
---

# CMS File System (VM/CMS)

The CMS (Conversational Monitor System) file system is used by IBM's VM/CMS
operating system, which has been in continuous use since the 1960s on IBM
mainframes. CMS runs as a guest operating system under the VM hypervisor —
one of the earliest virtualisation platforms.

The CMS filesystem is flat (no subdirectories). Each user gets their own
virtual disk (minidisk), so directory hierarchy is achieved through disk
assignment rather than filesystem structure.

## Characteristics

- Flat directory — no subdirectories
- Fixed or variable length records
- 800-byte blocks (original CDF), or 1024/2048/4096 bytes (EDF)
- Maximum file size: ~12.5MB (CDF), much larger with EDF
- Maximum records per file: 65,533
- Filenames: 8-character name + 8-character type (like CP/M's 8.3)
- EBCDIC character encoding
- Minidisk access via drive letters A-Z (max 10 simultaneous)

## Disk Layout

| Block | Purpose                                              |
|-------|------------------------------------------------------|
| 0-1   | IPL (boot) blocks                                    |
| 2     | Volume label (VOLSER, disk type, format info)        |
| 3     | Master File Directory (MFD) — directory header + QMSK bitmap |
| 4+    | File data, chain links, and directory entries         |

## File Status Table Entry (FST, 40 bytes)

| Offset | Size | Field     | Description                          |
|--------|------|-----------|--------------------------------------|
| 0x00   | 8    | FSTFNAME  | Filename (EBCDIC, space-padded)      |
| 0x08   | 8    | FSTFTYPE  | Filetype (EBCDIC, space-padded)      |
| 0x10   | 2    | FSTDATEW  | Date written (MMDD binary)           |
| 0x14   | 2    | FSTWRPNT  | Write pointer                        |
| 0x1E   | 2    | FSTRECFM  | Record format (fixed/variable)       |
| 0x20   | 4    | FSTLRECL  | Logical record length                |
| 0x24   | 2    | FSTBLKCT  | Block count                          |

## Formats

- **CDF** (CMS Disk Format): Original, 800-byte blocks, max 65,535 blocks
- **EDF** (Enhanced Disk Format): Introduced 1979, supports 1024-4096 byte
  blocks, multi-level chain links for larger files, up to 2^31 blocks

## Detection

The volume label (ADTSECT) at block 2 starts with EBCDIC "CMS1"
(`0xC3 0xD4 0xE2 0xF1`). The label offset from disk start is `2 * blocksize`:

| Block size | Label offset |
|------------|-------------|
| 512        | 0x400       |
| 1024       | 0x800       |
| 2048       | 0x1000      |
| 4096       | 0x2000      |

Source: IBM s390-tools `cmsfs-fuse/dasd.c`. For regular files, it probes
offsets {4096, 512, 2048, 1024, 8192} looking for the EBCDIC "CMS1" magic.

Additional validation: blocksize field at +0x0C (big-endian uint32) must be
512/1024/2048/4096; disk origin pointer at +0x10 must be 4 or 5; FST entry
size at +0x24 must be 64.

## Guest Support

VM/CMS runs on IBM System/370 and z/Architecture mainframes. The Hercules
mainframe emulator can run VM/CMS and access CMS minidisks. No Linux kernel
support exists for CMS filesystems.
