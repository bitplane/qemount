---
title: BeOS BFS
created: 1996
discontinued: 2001
related:
  - fs/hfsplus
detect:
  - offset: 0x20
    type: be32
    value: 0x42465331
    then:
      - offset: 0x44
        type: be32
        value: 0xdd121031
        then:
          - offset: 0x70
            type: be32
            value: 0x15b6830e
---

# Be File System (BFS)

The Be File System was developed by Dominic Giampaolo and Cyril Meurillon for
BeOS over ten months starting September 1996. It was designed as a modern
64-bit journaling filesystem optimized for multimedia workloads.

Note: Linux calls this "befs" to avoid confusion with the UnixWare Boot
Filesystem which is also called "bfs".

## Characteristics

- 64-bit addressing
- Journaling for crash recovery
- Extended attributes (arbitrary metadata on files)
- B+tree indexed directories
- Optimized for streaming media
- Case-insensitive filenames (optional)
- Live queries (database-like file searching)

## Structure

- Superblock at offset 0, 512 bytes
- Three magic numbers for validation:
  - 0x42465331 ("BFS1") at offset 0x20
  - 0xdd121031 at offset 0x44
  - 0x15b6830e at offset 0x70
- Endianness flag at offset 0x24 (0x42494745 = "BIGE" for big-endian)
- Block sizes: typically 1024, 2048, or 4096 bytes

## Legacy

- Native filesystem for BeOS (1996-2001)
- Used by Haiku OS (open-source BeOS successor)
- Linux read-only support via befs module
- Influenced modern filesystem designs with its attribute support
