---
title: Files-11
created: 1975
related:
  - format/fs/ntfs
  - format/fs/iso9660
detect:
  - offset: 0x3f0
    type: string
    value: "DECFILE11"
    then:
      - offset: 0x20d
        type: byte
        name: ods_level
---

# Files-11 (On-Disk Structure)

Files-11 is the filesystem used by DEC's RSX-11, VMS, OpenVMS, and related
operating systems. First introduced in 1975 with RSX-11, it was significantly
enhanced for VMS in 1977. Dave Cutler, who designed VMS and Files-11, later
led the Windows NT team at Microsoft — NTFS shows clear Files-11 influence
in its master file table concept and file header design.

## Structure Levels

| Level | Name  | Era       | Description                              |
|-------|-------|-----------|------------------------------------------|
| ODS-1 | 0201  | 1975      | RSX-11, flat directory structure          |
| ODS-2 | 0202  | 1977      | VMS, hierarchical directories (8 levels)  |
| ODS-3 | -     | -         | CD-ROM (ISO 9660)                         |
| ODS-4 | -     | -         | CD-ROM (High Sierra)                      |
| ODS-5 | 0205  | 1998      | Extended ODS-2, Unicode, unlimited depth   |

## Characteristics

- 512-byte blocks, grouped into clusters
- Unique File ID (FID): file number + sequence number + volume number
- File headers with checksums
- Index file (INDEXF.SYS) at the core — maps FIDs to file headers
- Storage bitmap (BITMAP.SYS) for allocation
- ACL-based security (from VMS 4.0+)
- Volume sets and stripe sets
- Filenames: 39.39 (ODS-2), extended in ODS-5
- File versioning (;1, ;2, etc.) up to 32767

## Disk Layout

- **LBN 0** (offset 0x000): Boot block
- **LBN 1** (offset 0x200): Primary home block
- **LBN 2+**: Index file bitmap, then file headers

Additional home block copies at LBNs 256, 512, 768, etc.

## Home Block (LBN 1, offset 0x200)

All multi-byte fields are little-endian.

| Offset | Size | Field   | Description                              |
|--------|------|---------|------------------------------------------|
| 0x200  | 2    | H.IBSZ  | Index file bitmap size (blocks)          |
| 0x202  | 4    | H.IBLB  | Index bitmap starting LBN                |
| 0x206  | 2    | H.FMAX  | Maximum number of files                  |
| 0x208  | 2    | H.SBCL  | Storage bitmap cluster factor            |
| 0x20A  | 2    | H.DVTY  | Disk device type                         |
| 0x20C  | 2    | H.VLEV  | Volume structure level (0201/0202 octal) |
| 0x20E  | 12   | H.VNAM  | Volume name (ASCII, null-padded)         |
| 0x21E  | 2    | H.VOWN  | Volume owner UIC                         |
| 0x220  | 2    | H.VPRO  | Volume protection code                   |
| 0x222  | 2    | H.VCHA  | Volume characteristics                   |
| 0x224  | 2    | H.DFPR  | Default file protection                  |
| 0x22C  | 1    | H.WISZ  | Default window size                      |
| 0x22D  | 1    | H.FIEX  | Default file extend                      |
| 0x22E  | 1    | H.LRUC  | Directory pre-access limit               |
| 0x22F  | 7    | H.REVD  | Last revision date (ASCII DDMMMYY)       |
| 0x236  | 2    | H.REVC  | Revision count                           |
| 0x23A  | 2    | H.CHK1  | Checksum of words 0-28                   |
| 0x23C  | 14   | H.VDAT  | Volume creation date (DDMMMYYHHMMSS)     |
| 0x3C8  | 4    | H.PKSR  | Pack serial number                       |
| 0x3D8  | 12   | H.INDN  | Volume name (ANSI format)                |
| 0x3E4  | 12   | H.INDO  | Volume owner (ANSI format)               |
| 0x3F0  | 12   | H.INDF  | Format type: "DECFILE11A " or "DECFILE11B"|
| 0x3FE  | 2    | H.CHK2  | Checksum of words 0-254                  |

## Detection

The string `"DECFILE11"` at absolute offset 0x3F0 (home block offset 496)
identifies a Files-11 volume. The character following it indicates the
variant:
- `"A"` — ODS-1 (RSX-11, original VAX/VMS)
- `"B"` — ODS-2 or ODS-5 (VMS/OpenVMS)

The ODS level byte at offset 0x20D (home block byte 13, high byte of H.VLEV)
gives the specific structure level (1, 2, or 5).

## System Files

| File | FID | Purpose                          |
|------|-----|----------------------------------|
| INDEXF.SYS  | 1,1 | Index file (master file table) |
| BITMAP.SYS  | 2,2 | Storage allocation bitmap      |
| BADBLK.SYS  | 3,3 | Bad block file                 |
| 000000.DIR  | 4,4 | Master file directory          |
| CORIMG.SYS  | 5,5 | Core image (RSX-11 only)       |
| VOLSET.SYS  | 6,6 | Volume set list                |
| CONTIN.SYS  | 7,7 | Continuation file              |
| BACKUP.SYS  | 8,8 | Backup journal                 |
| BADLOG.SYS  | 9,9 | Bad block log                  |

## Guest Support

OpenVMS runs on VAX, Alpha, Itanium, and x86-64. QEMU can emulate VAX
(qemu-system-alpha works for some OpenVMS versions). Linux has no Files-11
driver. The `vmsbackup` tool can extract files from VMS BACKUP savesets.
There is no `mkfs` equivalent outside of VMS itself — volumes are initialised
with the VMS `INITIALIZE` command.
