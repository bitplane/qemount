---
title: ADFS
created: 1983
related:
  - fs/filecore
detect:
  - offset: 0
    type: le16
    value: 0xadf5
---

# ADFS (Advanced Disc Filing System)

ADFS was the primary filesystem for Acorn computers, used on the BBC Master
and Acorn Archimedes series running RISC OS. It was built on top of FileCore,
the underlying disc handling module.

## Characteristics

- Hierarchical directory structure
- Case-insensitive filenames
- 10 character filename limit (early versions)
- File type information stored in load/exec addresses
- Multiple format variations (S, M, L, D, E, F, E+, F+)

## Structure

- Boot block at sector 0
- Map stored in zones
- Root directory ($)
- Fragmented file support in later versions

## Format Variations

| Format | Capacity | Block Size | Notes          |
|--------|----------|------------|----------------|
| S      | 160KB    | 256        | Single density |
| M      | 320KB    | 256        | Medium         |
| L      | 640KB    | 256        | Large          |
| D      | 800KB    | 1024       | Double density |
| E      | 800KB    | 1024       | New map        |
| F      | 1.6MB    | 1024       | High density   |
| E+/F+  | Various  | Various    | Hard disk      |

## Linux Support

Linux has read-only ADFS support in the kernel (fs/adfs/).
Writing is limited to existing files only.

## Historical Note

ADFS was developed alongside FileCore as part of Arthur OS,
which later became RISC OS. The format evolved over time to
support larger disks and better fragmentation handling.
