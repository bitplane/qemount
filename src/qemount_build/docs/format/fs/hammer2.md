---
title: HAMMER2
created: 2017
related:
  - format/fs/zfs
  - format/fs/btrfs
detect:
  - offset: 0x10000
    type: string
    value: "H2"
    then:
      - offset: 0x10002
        type: le16
        name: version
---

# HAMMER2 Filesystem

HAMMER2 was developed by Matthew Dillon for DragonFly BSD, released as the
default filesystem in DragonFly 5.0 (2017). It's a complete rewrite of the
original HAMMER filesystem with modern features.

## Characteristics

- Clustered filesystem design
- Copy-on-write
- Data deduplication (inline)
- Compression (LZ4, ZLIB)
- Multi-volume spanning
- Maximum file size: 1 EB
- Maximum volume size: 1 EB
- Instant snapshots

## Structure

- Volume header at offset 0x10000
- "H2" magic signature
- Freemap for space allocation
- B-tree based metadata
- Topology with multiple roots
- Blockref chains

## Key Features

- **Clustering**: Multi-master filesystem
- **Snapshots**: Instant, unlimited
- **Dedup**: Inline block-level
- **Compression**: Per-file or global
- **Fine-grained Locking**: SMP scalability
- **Crash Recovery**: No fsck needed

## vs HAMMER1

| Feature    | HAMMER1      | HAMMER2 |
|------------|--------------|---------|
| Max file   | 1 EB         | 1 EB    |
| Dedup      | Post-process | Inline  |
| Clustering | No           | Yes     |
| Design     | B-tree       | B-tree+ |
| Recovery   | Fsck         | None    |

## Multi-Volume

HAMMER2 can span multiple physical volumes:
```
hammer2 volume add /dev/da1 /mnt
hammer2 volume list /mnt
```

## Platform Support

- **DragonFly BSD**: Native, default filesystem
- **Linux**: No support
- **FreeBSD**: No support
- **NetBSD**: No support

## Historical Note

HAMMER (version 1) was introduced in DragonFly 2.0 (2008) and was
revolutionary for its time. HAMMER2 addresses scalability and
clustering limitations of the original design.
