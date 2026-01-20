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

## Current Status

- **cpmtools**: Userspace tools can read/write images
- No Linux kernel driver
- FUSE implementation may exist
- Many preserved disk images available
- Format is well documented

## Implementation Notes

Possible approaches for qemount support:

1. **FUSE**: Use or adapt existing FUSE implementation
2. **Kernel module**: Format is simple enough for a .ko
3. **Emulation**: Run CP/M in emulator, bridge files out

The filesystem structure is straightforward, but the challenge is handling
the many different disk parameter variations (different machines used
different block sizes, directory sizes, and skew factors).

## References

The "Disk Parameter Block" (DPB) defines the format for each disk type.
Tools like cpmtools use definition files to handle the variations.
