---
title: SYSV68
created: 1985
related:
  - format/pt/mbr
detect:
  - offset: 0x1FE
    type: be16
    value: 0x55AA
    name: boot_signature
    then:
      - offset: 0x600
        type: string
        name: sysv_marker
---

# SYSV68 (Motorola 68k System V)

SYSV68 is the partitioning scheme used by System V Unix on
Motorola 68000-series workstations from various vendors.

## Characteristics

- Big-endian format (68k native)
- System V Unix based
- Used on Motorola VME systems
- Vendor-specific variations

## Platforms

- **Motorola MVME**: VMEbus computers
- **Integrated Solutions**: Various 68k systems
- **Other 68k Unix**: Various vendors

## Structure

The format varies by vendor but typically includes:

```
Offset  Size  Description
0       512   Boot block
512     ...   Volume header
...
0x600   ...   Partition data
```

## Linux Support

Linux kernel has basic SYSV68 partition support
(CONFIG_SYSV68_PARTITION). Detection heuristics
check for specific patterns in the boot block
and volume header.

## Historical Note

The 68k architecture was popular for Unix workstations
in the 1980s before RISC processors took over. Sun's
original workstations were 68k-based before SPARC.

## Related Formats

- **Sun-2/Sun-3**: Early Sun 68k systems used different format
- **Apollo Domain**: Apollo's 68k workstations had unique scheme
- **HP 9000/300**: HP's 68k systems used HP-UX format
