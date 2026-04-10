---
title: EUMEL
created: 1978
discontinued: 1992
detect:
  - offset: 5120
    type: string
    value: "EUMEL"
---

# EUMEL

EUMEL (Extendable multi User Microprocessor EL system) was an operating system
developed at the University of Bielefeld, Germany, starting in the late 1970s.
It was primarily used in German educational institutions and featured its own
programming language called ELAN.

## Characteristics

- Multi-user, multitasking operating system
- Custom filesystem (not Unix-derived)
- Written primarily in ELAN programming language
- Hardware abstraction via "SHard" (Software/Hardware interface)
- Ran on various microprocessors (Z80, 8086, etc.)

## History

- 1978: Development begins at University of Bielefeld
- 1979: First public release
- 1980s: Widely used in German schools and universities
- 1988: Evolved into L3 operating system
- 1992: Development effectively ceased

## Structure

EUMEL used its own filesystem format, unrelated to Unix or DOS filesystems.
The urlader (boot loader) occupies blocks 10-109 (100 blocks of 512 bytes,
starting at byte offset 5120). Page size is 512 bytes throughout.

## Detection

The ASCII string `EUMEL` (5 bytes) at offset 5120 (block 10) identifies
the start of the urlader. Source: `BOOT.ASM` from the SHard x86-AT layer.
MBR partition type `0x45` ('E') also identifies EUMEL partitions.

## MBR Partition Types

- 0x46-0x4F: Reserved for EUMEL/Elan

Multiple partition types were allocated, possibly for different uses
(system, data, swap equivalent, etc.).

## Current Status

- Source code may be available in archives
- Disk images likely exist from preservation efforts
- No modern driver implementation
- Would require reverse engineering or emulation approach

## Implementation Notes

Possible approaches for qemount support:

1. **Native driver**: Reverse engineer filesystem format, implement reader
2. **Emulation**: Run EUMEL in emulator, use 9p or similar to export files
3. **Hybrid**: Boot minimal EUMEL kernel in QEMU, bridge to host

Given EUMEL's educational origins, documentation of the filesystem format
may exist in German academic papers or technical manuals.

## Related

EUMEL evolved into L3, which later influenced the L4 microkernel family,
though the filesystem formats are unrelated.
