---
title: NTFS
type: fs
created: 1993
related:
  - fs/exfat
  - fs/ext4
detect:
  - offset: 0x03
    type: string
    value: "NTFS    "
    then:
      - offset: 0x1FE
        type: le16
        value: 0xAA55
      - offset: 0x48
        type: le64
        name: mft_cluster
---

# NTFS (New Technology File System)

NTFS was developed by Microsoft for Windows NT 3.1, released in 1993. It
replaced FAT as the primary Windows filesystem and remains the default for
Windows system drives.

## Characteristics

- 64-bit cluster addresses
- Maximum volume size: 8 PB (practical), 16 EB (theoretical)
- Maximum file size: 16 EB (256 TB practical on Windows)
- Long filenames up to 255 UTF-16 characters
- Case-preserving, case-insensitive (configurable)
- Journaling (metadata only by default)
- ACL permissions and encryption (EFS)
- Compression (per-file/folder)
- Hard links, symbolic links, junction points
- Sparse files and alternate data streams

## Structure

- Boot sector at offset 0
- OEM label "NTFS    " at offset 0x03
- Boot signature 0xAA55 at offset 0x1FE
- Master File Table (MFT) - database of all files
- MFT Mirror (backup of first MFT entries)
- Everything is a file (including metadata)

## Key Fields

| Offset | Size | Field |
|--------|------|-------|
| 0x03 | 8 | OEM name ("NTFS    ") |
| 0x0B | 2 | Bytes per sector |
| 0x0D | 1 | Sectors per cluster |
| 0x28 | 8 | Total sectors |
| 0x30 | 8 | MFT cluster number |
| 0x38 | 8 | MFT mirror cluster |
| 0x40 | 1 | Clusters per MFT record |

## Special Files ($MFT)

| Entry | Name | Purpose |
|-------|------|---------|
| 0 | $MFT | Master File Table itself |
| 1 | $MFTMirr | Backup of first 4 MFT entries |
| 2 | $LogFile | Transaction journal |
| 3 | $Volume | Volume information |
| 4 | $AttrDef | Attribute definitions |
| 5 | . | Root directory |
| 6 | $Bitmap | Cluster allocation bitmap |
| 7 | $Boot | Boot sector |
| 8 | $BadClus | Bad cluster list |

## Linux Support

- Read/write via ntfs3 driver (kernel 5.15+, full support)
- Read/write via ntfs-3g FUSE (older, slower)
- Legacy read-only ntfs driver
