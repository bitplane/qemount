---
title: DragonFly BSD Disklabel
created: 2003
related:
  - format/pt/bsd-disklabel
  - format/fs/hammer2
detect:
  - offset: 512
    type: le32
    value: 0x82564557
    name: disklabel_magic
  - offset: 0
    type: le32
    value: 0xc4464c59
    name: disklabel64_magic
---

# DragonFly BSD Disklabel

DragonFly BSD uses BSD disklabel for compatibility, plus its own
64-bit disklabel format for modern systems.

## Formats

### Traditional BSD Disklabel
- Magic 0x82564557
- 16 partitions (a-p)
- 32-bit sector addresses

### DragonFly Disklabel64
- Magic 0xC4464C59 ("YLF\xC4")
- 64-bit sector addresses
- Designed for HAMMER/HAMMER2

## Disklabel64 Structure

```
Offset  Size  Description
0       4     Magic (0xC4464C59)
4       4     CRC32
8       4     Alignment
12      4     Number of partitions
16      8     Total size
24      8     Boot2 offset
32      8     Boot2 size
40      ...   Partition entries
```

## Partition Entry (Disklabel64)

```
Offset  Size  Description
0       8     Start offset
8       8     Size
16      16    Filesystem UUID
32      32    Storage UUID
```

## Use with HAMMER2

DragonFly's native HAMMER2 filesystem typically uses:
- Disklabel64 for modern installs
- GPT on UEFI systems
- Traditional disklabel for compatibility

## Linux Support

Linux handles traditional BSD disklabel format.
Disklabel64 is DragonFly-specific and not parsed
by Linux kernel.
