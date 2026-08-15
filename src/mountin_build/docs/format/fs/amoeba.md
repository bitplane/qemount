---
title: Amoeba
created: 1983
discontinued: 1996
detect:
  - offset: 0
    type: be32
    value: 0x70bdce21
---

# Amoeba

Amoeba was a distributed operating system developed at Vrije Universiteit
Amsterdam (VU Amsterdam) by Andrew S. Tanenbaum and colleagues. The same
Tanenbaum who created MINIX and wrote the influential operating systems
textbooks.

## Background

Amoeba was a research project exploring distributed computing - the goal
was to make a collection of networked computers appear as a single unified
system. Users wouldn't know (or care) which machine was running their
programs or storing their files.

## Characteristics

- Microkernel architecture
- Distributed filesystem - files accessible across the network transparently
- Object-based capability system for security
- RPC-based communication
- Group communication primitives
- Ran on various hardware (Sun, i386, etc.)

## Filesystem

The Amoeba filesystem was designed for distributed access:

- Bullet server - high-performance file server
- Directory server - hierarchical naming
- Immutable files (copy-on-write semantics)
- Capabilities used for file access control

## MBR Partition Types

| Type | Name         | Notes                           |
|------|--------------|---------------------------------|
| 0x90 | Amoeba       | Filesystem partition            |
| 0x91 | Amoeba BBT   | Bad Block Table (disk metadata) |

## History

- 1983: Project begins at VU Amsterdam
- 1980s: Active development and research
- 1990s: Used in distributed systems courses
- 1996: Active development winds down
- Source code released for educational use

## Detection

The Bullet server superblock at block 0 (offset 0) starts with magic number
`0x70BDCE21` as a big-endian 32-bit integer. Defined as `S_MAGIC` in
`src/h/server/bullet/superblk.h`. All multi-byte fields are stored
big-endian on disk. The superblock also has a 16-bit checksum covering
the entire 512-byte block.

## Current Status

- Source code available for research/education
- No modern kernel driver
- Academic papers document the design
- Disk images may exist in university archives

## Academic Significance

Amoeba influenced distributed systems research and education. Concepts
from Amoeba appeared in later systems. The project demonstrated that
transparent distributed computing was achievable, even if not yet
practical for mainstream use.

## References

- Tanenbaum, A.S., et al. "Experiences with the Amoeba Distributed
  Operating System" - Communications of the ACM, 1990
- Source code and documentation at VU Amsterdam archives
