---
title: MFS
created: 1984
discontinued: 1985
related:
  - format/fs/hfs
  - format/fs/hfsplus
detect:
  - offset: 0x400
    type: be16
    value: 0xd2d7
    then:
      - offset: 0x412
        type: be16
        name: block_count
      - offset: 0x414
        type: be32
        name: block_size
---

# Macintosh File System (MFS)

MFS was the original filesystem on the Macintosh, introduced in January 1984
with System 1. It was a flat filesystem designed for the 400KB single-sided
floppy drives of the original Mac. Folders were an illusion maintained by the
Finder, not the filesystem itself.

MFS was replaced by HFS in September 1985, which added real hierarchical
directories via B-tree catalogues. Mac OS 7.6 dropped write support, and
Mac OS 8 removed MFS support entirely.

## Characteristics

- Flat directory (no hierarchy; folders are a Finder concept)
- Maximum volume size: 20MB
- Maximum file size: 20MB
- Maximum files: ~4094
- Dual forks per file (data + resource)
- 12-bit allocation block map (max 4094 blocks)
- Filenames up to 255 characters (Mac OS Roman)
- Creator/type codes in Finder info
- Timestamps: seconds since 1904-01-01 00:00 local time (unsigned 32-bit)
- All values big-endian

## Disk Layout

- Blocks 0-1: boot blocks (system startup info)
- Block 2: Master Directory Block (MDB)
- Block 3: MDB backup (on 400KB floppies this is block 799)
- Blocks 4-15: file directory (12 blocks on 400KB volumes)
- Blocks 16+: allocation blocks containing file data
- Last two blocks: backup MDB copy

## Master Directory Block (offset 0x400)

| Offset | Size | Field      | Description                          |
|--------|------|------------|--------------------------------------|
| 0x00   | 2    | drSigWord  | Signature: 0xD2D7                    |
| 0x02   | 4    | drCrDate   | Volume creation date                 |
| 0x06   | 4    | drLsBkUp   | Last backup date                     |
| 0x0A   | 2    | drAtrb     | Attributes (bit 7: hw lock, 15: sw)  |
| 0x0C   | 2    | drNmFls    | Number of files in directory         |
| 0x0E   | 2    | drDirSt    | First directory block number         |
| 0x10   | 2    | drBlLen    | Directory length in blocks           |
| 0x12   | 2    | drNmAlBlks | Number of allocation blocks          |
| 0x14   | 4    | drAlBlkSiz | Allocation block size in bytes       |
| 0x18   | 4    | drClpSiz   | Default clump size                   |
| 0x1C   | 2    | drAlBlSt   | First allocation block in block map  |
| 0x1E   | 4    | drNxtFNum  | Next unused file number              |
| 0x22   | 2    | drFreeBks  | Number of free allocation blocks     |
| 0x24   | 28   | drVN       | Volume name (length-prefixed string) |

## Allocation Block Map

Follows the MDB within the same 512-byte block. Each entry is 12 bits,
packed big-endian: bytes AB CD EF become values 0x0ABC and 0x0DEF.

- 0x000: block is free
- 0x001: last block in file chain
- 0x002-0xFFE: next block number in chain
- 0xFFF: reserved

Block numbers 0 and 1 are reserved; the first map entry is for block 2.

## File Directory Entry

Variable-length entries aligned to 16-bit boundaries, never crossing block
boundaries. An entry with flFlags == 0 marks end of entries in that block.

| Offset | Size | Field    | Description                        |
|--------|------|----------|------------------------------------|
| 0x00   | 1    | flFlags  | Bit 7: in use, bit 0: locked       |
| 0x01   | 1    | flTyp    | Version (usually 0x00)             |
| 0x02   | 16   | flUsrWds | Finder info (type/creator codes)   |
| 0x12   | 4    | flFlNum  | File number (unique, never reused) |
| 0x16   | 2    | flStBlk  | First data fork alloc block        |
| 0x18   | 4    | flLgLen  | Data fork logical (actual) length  |
| 0x1C   | 4    | flPyLen  | Data fork physical length          |
| 0x20   | 2    | flRStBlk | First resource fork alloc block    |
| 0x22   | 4    | flRLgLen | Resource fork logical length       |
| 0x26   | 4    | flRPyLen | Resource fork physical length      |
| 0x2A   | 4    | flCrDat  | Creation date                      |
| 0x2E   | 4    | flMdDat  | Modification date                  |
| 0x32   | n    | flNam    | Filename (length byte + string)    |

## Detection

Signature 0xD2D7 at offset 0x400 (1024). This is the same offset as the HFS
signature (0x4244), so checking the signature value distinguishes the two.

## Guest Support

No modern OS includes an MFS driver. The format was already obsolete by 1986.
Mounting would require a classic Mac OS emulator (e.g. Mini vMac with System 1-6)
or a userspace reader. No Linux kernel support has ever existed for MFS.
