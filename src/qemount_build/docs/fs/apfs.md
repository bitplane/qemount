---
title: APFS
created: 2017
related:
  - fs/hfsplus
  - fs/zfs
detect:
  - offset: 0x20
    type: string
    value: "NXSB"
---

# APFS (Apple File System)

APFS was developed by Apple and released with macOS High Sierra (10.13) in
2017. It replaced HFS+ as the default filesystem for all Apple platforms
including macOS, iOS, tvOS, and watchOS.

## Characteristics

- Copy-on-write design
- Space sharing (container model)
- Native encryption (per-file or per-volume)
- Snapshots and clones
- 64-bit inodes
- Nanosecond timestamps
- Maximum file size: 8 EB
- Maximum volume size: 8 EB
- Optimized for flash/SSD storage

## Structure

- Container superblock at block 0
- "NXSB" magic at offset 0x20
- Multiple volumes share container space
- B-tree based metadata
- Object map for physical-to-virtual mapping
- Checkpoint system for crash consistency

## Key Features

- **Space Sharing**: Multiple volumes in one container
- **Clones**: Instant file/directory copies
- **Snapshots**: Point-in-time volume state
- **Encryption**: FileVault integration, per-file keys
- **Crash Protection**: Copy-on-write metadata
- **Sparse Files**: Efficient storage

## Container vs Volume

```
Container (Physical)
├── Volume 1 (Macintosh HD)
├── Volume 2 (Data)
├── Volume 3 (Preboot)
└── Volume 4 (Recovery)
```

All volumes share the container's free space dynamically.

## Linux Support

No native Linux kernel support. Third-party options:
- **apfs-fuse**: Read-only FUSE driver
- **linux-apfs-rw**: Experimental read-write driver
- **apfsutil**: Command-line tools

## Limitations

- No native Windows support
- Limited cross-platform tools
- Encryption complicates recovery
- Apple-proprietary format
