---
title: CP/M
created: 1974
discontinued: 1990
---

# CP/M

CP/M (Control Program for Microcomputers) was developed by Gary Kildall at
Digital Research in 1974. It dominated 8-bit microcomputers before MS-DOS
took over the IBM PC market. DOS borrowed heavily from CP/M, including the
8.3 filename convention and many API concepts.

## Characteristics

- Flat namespace (no subdirectories)
- 8.3 filenames (8 character name + 3 character extension)
- User areas 0-15 for basic file separation
- Directory entries at disk start
- Simple allocation blocks
- Various disk parameter formats (block sizes, directory sizes vary)

## Variants

| Variant | Processor | Notes |
|---------|-----------|-------|
| CP/M-80 | 8080/Z80 | Original, most common |
| CP/M-86 | 8086/8088 | IBM PC compatible |
| MP/M | 8080/Z80 | Multi-user version |
| CP/M-68K | 68000 | Motorola version |

## Structure

- Boot tracks (system reserved)
- Directory entries (fixed location, size varies by format)
- Data area (allocation blocks)

Directory entries are 32 bytes each:
- User number (1 byte)
- Filename (8 bytes)
- Extension (3 bytes)
- Extent info (4 bytes)
- Block pointers (16 bytes)

## MBR Partition Type

- 0x52: CP/M-86 / Microport SysV/AT

## History

- 1974: Gary Kildall creates CP/M at Digital Research
- 1977: Becomes dominant microcomputer OS
- 1981: IBM chooses MS-DOS over CP/M-86 for IBM PC
- 1991: Digital Research acquired by Novell
- 1990s: Fades from commercial use

## Detection

CP/M disks are not self-describing. The Disk Parameter Block (DPB) — which
defines sector size, block size, directory layout — is not stored on disk.
It lives in the BIOS ROM. There is no superblock, no magic number, no
version field. Freshly formatted disks are filled with 0xE5 (which also
marks unused directory entries), making blank CP/M disks ambiguous.

The `file` magic database has no CP/M filesystem entries. Neither does
libblkid.

**Amstrad PCW/Spectrum +3 exception**: These store a 16-byte format
descriptor at track 0, sector 1. Byte 0 is 0x00 (SS/SD) or 0x03 (DS/DD).
The PCW16 extension uses 0xE9/0xEB (DOS JMP) with "CP/M" at offsets 0x2B
and 0x7C. This is the only CP/M variant with a detectable signature.

**Heuristic approach**: Try candidate geometries (matched by image size),
locate where the directory would be, validate that all 32-byte entries have
valid status bytes (0x00-0x1F or 0xE5), filenames are printable ASCII, and
block pointers are self-consistent. High false-positive risk.

Generic CP/M detection is not feasible for qemount. User-specified format
would be required.

## Current Status

- **cpmtools**: Userspace tools can read/write images (requires `-f format`)
- No Linux kernel driver
- Many preserved disk images available
- Format is well documented but varies per machine
