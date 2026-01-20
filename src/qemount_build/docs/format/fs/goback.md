---
title: GoBack
created: 1998
discontinued: 2007
---

# GoBack

GoBack was a disk recovery and rollback system that allowed users to "go back"
to a previous disk state after malware infections, failed software installs,
or system corruption. Originally developed by Wild File, later acquired by
Adaptec, Roxio (2001), and finally Symantec (2003).

## Characteristics

- Block-level copy-on-write versioning
- Intercepts all disk writes at driver level
- Stores original data plus chain of deltas
- Point-in-time recovery to any previous state
- Wrapped underlying filesystem (usually FAT16/FAT32/NTFS)

## Structure

The GoBack partition contains:

- Original filesystem state (base image)
- Delta/snapshot chain with timestamps
- Metadata index for navigating versions
- Configuration data

The format is essentially a versioned block container wrapping a real
filesystem. To access the data, you parse the container and replay
deltas to reconstruct the filesystem at a desired point in time.

## History

- 1998: Wild File releases GoBack
- 2000: Adaptec acquires Wild File
- 2001: Roxio acquires from Adaptec
- 2003: Symantec acquires from Roxio
- 2007: Symantec discontinues product

## Current Status

- No known open source implementation
- Format is proprietary and undocumented
- Disk images may exist in archives
- Would require reverse engineering to support

## MBR Partition Type

- 0x44: GoBack

## Implementation Notes

Supporting GoBack would require:

1. Reverse engineering the container format
2. Parsing the delta chain structure
3. Implementing block-level replay to reconstruct states
4. Exposing reconstructed filesystem for mounting

The underlying filesystem (FAT/NTFS) would then be mountable with
standard drivers once reconstructed.
