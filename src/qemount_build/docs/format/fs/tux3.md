---
title: Tux3
created: 2008
related:
  - format/fs/btrfs
  - format/fs/ext4
detect:
  - offset: 0x1000
    type: string
    value: "tux3"
    then:
      - offset: 0x100e
        type: be16
        name: block_bits
      - offset: 0x1014
        type: be64
        name: vol_blocks
---

# Tux3

Tux3 is an experimental versioning filesystem created by Daniel Phillips,
first announced in 2008. It was designed as a successor to his earlier Tux2
filesystem, featuring copy-on-write versioning, B-trees for metadata, and a
log-based commit model. It was never merged into the mainline Linux kernel.

## Characteristics

- Copy-on-write versioning (snapshot-like)
- B-tree based metadata (inode table, directory entries, extents)
- Delta commit model with log chain
- Configurable block size (default 4KB)
- Atom-based extended attributes
- Orphan table for crash recovery
- Maximum filename length: 255 characters

## Disk Layout

The first 4KB (0x1000 bytes) is reserved. The superblock is at offset 0x1000.
Block size is configurable but defaults to 4096.

### Superblock (offset 0x1000)

All multi-byte fields are big-endian.

| Offset | Size | Field         | Description                          |
|--------|------|---------------|--------------------------------------|
| 0x1000 | 8    | magic         | "tux3\\x20\\x12\\x12\\x20"          |
| 0x1008 | 8    | birthdate     | Volume creation timestamp            |
| 0x1010 | 8    | flags         | Filesystem flags                     |
| 0x1018 | 2    | blockbits     | log2(block size), typically 12       |
| 0x101A | 6    | unused        | Padding                              |
| 0x1020 | 8    | volblocks     | Volume size in blocks                |
| 0x1028 | 8    | iroot         | Inode table B-tree root              |
| 0x1030 | 8    | oroot         | Orphan table B-tree root             |
| 0x1038 | 8    | usedinodes    | Count of allocated inode numbers     |
| 0x1040 | 8    | nextalloc     | Next allocation hint                 |
| 0x1048 | 8    | atomdictsize  | Atom dictionary size                 |
| 0x1050 | 4    | freeatom      | First free atom in atom table        |
| 0x1054 | 4    | atomgen       | Next atom number                     |
| 0x1058 | 8    | logchain      | Most recent delta commit block       |
| 0x1060 | 4    | logcount      | Log blocks in current chain          |

## Magic

The 8-byte magic string is `"tux3"` followed by `0x20 0x12 0x12 0x20`, which
encodes the date 2012-12-20 — the last incompatible format change. Detection
can match on the first 4 bytes `"tux3"` at offset 0x1000.

## B-tree Node Types

Internal nodes use magic numbers to identify their type:

| Magic  | Type   | Description               |
|--------|--------|---------------------------|
| 0x10ad | Log    | Log/journal entry         |
| 0xb4de | Bnode  | B-tree internal node      |
| 0x1eaf | Dleaf  | Directory leaf            |
| 0xbeaf | Dleaf2 | Directory leaf (v2)       |
| 0x90de | Ileaf  | Inode leaf                |
| 0x6eaf | Oleaf  | Orphan/other leaf         |

## Guest Support

Tux3 was never merged into mainline Linux. It exists as an out-of-tree module
at github.com/danielbot/tux3. The `tux3` userspace tool provides mkfs, fsck,
and FUSE mount capabilities.
