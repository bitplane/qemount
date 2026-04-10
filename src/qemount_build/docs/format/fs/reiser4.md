---
title: Reiser4
created: 2004
related:
  - format/fs/reiserfs
  - format/fs/btrfs
detect:
  - offset: 0x11034
    type: string
    value: "ReIsEr40FoRmAt"
---

# Reiser4

Reiser4 was developed by Hans Reiser and Namesys as the successor to
ReiserFS (v3). It was a ground-up redesign with a plugin-based architecture,
dancing trees (a variant of B+ trees that delays balancing), and atomic
operations. It was never merged into the mainline Linux kernel despite years
of development, and has been maintained as an out-of-tree patch set.

## Characteristics

- Plugin-based architecture (everything is a plugin: files, directories,
  hashing, compression, encryption)
- Dancing trees: delayed balancing for better write performance
- Atomic operations: writes are all-or-nothing
- Wandering logs: hybrid journal/copy-on-write transaction model
- Extent-based allocation
- Maximum file size: 8 EB (theoretical)
- Maximum volume size: 16 EB (theoretical)
- Dynamic inode allocation (no fixed inode count)
- Tail packing (small files stored inline in tree nodes)
- Transparent compression and encryption via plugins

## Disk Layout

The first 64KB (0x10000 bytes) is reserved for boot loaders and disk labels.

### Master Superblock (offset 0x10000)

The master superblock identifies the filesystem to the VFS layer.

| Offset  | Size | Field      | Description                    |
|---------|------|------------|--------------------------------|
| 0x10000 | 4    | magic      | 0x52345362 ("R4Sb")            |

### Format Superblock (offset 0x11000)

The format-specific superblock follows at offset 0x11000 (master offset +
4096). All fields are little-endian.

| Offset  | Size | Field             | Description                   |
|---------|------|-------------------|-------------------------------|
| 0x11000 | 8    | block_count       | Total blocks in filesystem    |
| 0x11008 | 8    | free_blocks       | Number of free blocks         |
| 0x11010 | 8    | root_block        | Tree root block number        |
| 0x11018 | 8    | oid               | Next free object ID           |
| 0x11020 | 8    | file_count        | Number of files               |
| 0x11028 | 8    | flushes           | Superblock flush counter      |
| 0x11030 | 4    | mkfs_id           | Unique filesystem identifier  |
| 0x11034 | 16   | magic             | "ReIsEr40FoRmAt\0"            |
| 0x11044 | 2    | tree_height       | Height of the B+ tree         |
| 0x11046 | 2    | formatting_policy | (unused)                      |
| 0x11048 | 8    | flags             | Filesystem flags              |
| 0x11050 | 4    | version           | On-disk format version        |
| 0x11054 | 4    | node_pid          | Node plugin ID                |

### Journal

- Journal header: block at `(0x10000 / 4096) + 3` = block 19
- Journal footer: block at `(0x10000 / 4096) + 4` = block 20

## Detection

The format magic string `"ReIsEr40FoRmAt"` at offset 0x11034 is the primary
detection method. The master superblock magic `0x52345362` at offset 0x10000
provides a secondary check.

Note: ReiserFS (v3) uses the same superblock offset (0x10000) but different
magic strings (`"ReIsErFs"`, `"ReIsEr2Fs"`, `"ReIsEr3Fs"` at offset 0x10034).

## Guest Support

Reiser4 was never merged into the mainline Linux kernel. It exists as an
out-of-tree patch set maintained at github.com/edward6/reiser4. Mounting
requires a kernel with the reiser4 patch applied, or a distribution that
includes it (some older Gentoo/SUSE kernels did).

The `reiser4progs` package provides `mkfs.reiser4`, `fsck.reiser4`, and
related tools.
