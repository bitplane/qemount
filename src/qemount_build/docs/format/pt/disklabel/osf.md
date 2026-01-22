---
title: DEC OSF/1 Disklabel
created: 1992
related:
  - format/pt/disklabel/ultrix
detect:
  - offset: 0
    type: le64
    value: 0x82564557
    name: osf_magic
---

# DEC OSF/1 / Tru64 Disklabel

The OSF/1 disklabel was used by DEC's OSF/1 (later Digital Unix, then
Tru64) on Alpha systems. It's distinct from the earlier Ultrix format
used on VAX and MIPS.

## Characteristics

- Little-endian (Alpha native)
- Similar structure to BSD disklabel
- Up to 8 partitions
- Used on DEC Alpha workstations/servers
- Magic number 0x82564557 (same as BSD)

## History

- **OSF/1** (1992): Original name
- **Digital Unix** (1995): After DEC rename
- **Tru64 Unix** (1999): After Compaq acquisition
- **End of life** (2012): HP discontinued

## Structure

Similar to BSD disklabel but with Alpha-specific fields:

```
Offset  Size  Description
0       4     Magic (0x82564557)
...           (similar to BSD disklabel)
```

## vs Ultrix

| Feature  | Ultrix     | OSF/1      |
|----------|------------|------------|
| Platform | VAX, MIPS  | Alpha      |
| Endian   | Little     | Little     |
| Magic    | 0x00032957 | 0x82564557 |
| Era      | 1984-1995  | 1992-2012  |

## vs BSD Disklabel

OSF/1 disklabel shares the magic number with BSD disklabel.
Linux's partition parser handles both through the same code path
(CONFIG_OSF_PARTITION), distinguishing by context.

## Linux Support

Linux kernel parses OSF/1 disklabels (CONFIG_OSF_PARTITION).
This is the same config option that handles BSD disklabels.
