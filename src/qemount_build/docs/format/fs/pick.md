---
title: PICK
created: 1965
---

# PICK Filesystem

PICK is an integrated operating system and database developed by Dick Pick
and Don Nelson in 1965 (originally as GIRLS - Generalized Information
Retrieval Language System on IBM System/360). Unlike traditional systems,
PICK combines the OS, filesystem, and database into one unified platform.

## Characteristics

- Hash-file system with linear probing
- Record-oriented storage (not file-oriented)
- Schema-less database design
- 512-byte sectors with 12-byte link overhead (500 usable)
- Forward/back sector links for unlimited string space
- Disk directly addressable by instruction set
- Memory acts as cache for disk-resident data

## Structure

### Sector Format

Each 512-byte sector contains:
- 12 bytes: forward and back links to other sectors
- 500 bytes: usable data

The link structure allows essentially unlimited string space, with
the disk being directly addressable.

### Data Organization

Hierarchical structure:
- Accounts
- Dictionaries
- Files
- Sub-files

### Records

- Variable-length records identified by unique keys
- Fields delimited by ASCII 254 (attribute mark)
- No explicit data types - all data stored as strings
- Non-first-normal-form (denormalized, no joins needed)

### Dictionaries

Every file has an attached dictionary describing its structure
through attributes, values, and subvalues.

## MBR Partition Type

| Type | Description |
|------|-------------|
| 0x40 | PICK        |

Note: 0x40 is also used by Venix 80286 (different system).

## History

- 1965: GIRLS developed at TRW on IBM 360
- 1970s: Licensed to minicomputer vendors
- 1983: R83 release for IBM PC-XT/AT
- 1989: Advanced PICK (AP) - runs within Windows

## Implementations

PICK was licensed and implemented by many vendors:
- PICK Systems (original)
- Reality (Microdata)
- UniVerse (now Rocket Software)
- UniData
- jBASE
- OpenQM

## Current Status

- Still in use in niche markets
- Modern implementations run on standard OSes
- Original partition-based version largely obsolete
- No Linux kernel driver
- Format is proprietary

## References

- [Wikipedia: Pick operating system](https://en.wikipedia.org/wiki/Pick_operating_system)
- [Pick is a living fossil of computer history](https://csixty4.medium.com/pick-is-a-living-fossil-of-computer-history-36d74408d557)
