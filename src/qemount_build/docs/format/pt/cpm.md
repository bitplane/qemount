---
title: CP/M-86
created: 1981
related:
  - format/pt/mbr
detect:
  - offset: 0x1C2
    type: u8
    value: 0x52
    name: cpm86_type
---

# CP/M-86 Partition

CP/M-86 was Digital Research's 16-bit version of CP/M for 8086/8088
processors. It used specific MBR partition types.

## Characteristics

- MBR-based partitioning
- Partition type 0x52
- 8086/8088 compatible
- Pre-dates DOS dominance

## Partition Types

| Type | Description |
|------|-------------|
| 0x52 | CP/M-86 |
| 0x53 | Ontrack DM6 (sometimes confused) |

## Historical Context

Timeline:
- **1981**: CP/M-86 released
- **1981**: IBM chooses PC DOS (MS-DOS) for IBM PC
- **1982**: CP/M-86 for IBM PC released
- **1983+**: DOS dominates, CP/M fades

CP/M-86 lost the IBM PC market to MS-DOS, though it
was technically similar. The partition type remains
in MBR specifications.

## Filesystem

CP/M-86 used its own filesystem:
- Directory at fixed location
- Extent-based allocation
- No subdirectories
- 8.3 filenames

## Related Systems

- **CP/M-68k**: 68000 version
- **MP/M**: Multi-user CP/M
- **Concurrent DOS**: DR's DOS successor
- **DOS Plus**: CP/M + DOS compatibility

## Linux Support

Linux recognizes CP/M-86 partition type but has no
filesystem support. Useful mainly for:
- Vintage computing preservation
- Forensic analysis
- Historical disk imaging

## Modern Use

Virtually none. CP/M-86 disks are rare collectibles.
Emulators like 86Box can run CP/M-86 for historical
purposes.
