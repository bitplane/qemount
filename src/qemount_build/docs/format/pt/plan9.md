---
title: Plan 9
created: 1992
related:
  - format/pt/mbr
detect:
  - offset: 0x1BE
    type: u8
    value: 0x39
    name: plan9_partition_type
---

# Plan 9 Partition Table

Plan 9 from Bell Labs uses a simple ASCII-based partition table format.
The partition information is stored as human-readable text.

## Characteristics

- ASCII text format
- Human-readable partition table
- Simple parsing
- Stored within Plan 9 MBR partition (type 0x39)
- No complex binary structures

## MBR Integration

Plan 9 uses standard MBR at disk level:
- Partition type 0x39 identifies Plan 9 partition
- ASCII partition table inside that partition

## ASCII Format

The partition table is plain text:

```
part plan9 0 1000000
part 9fat 0 100000
part nvram 100000 100001
part fossil 100001 900000
part swap 900000 1000000
```

Format: `part <name> <start> <end>`

Sectors are in units of the disk's sector size.

## Common Partitions

| Name | Purpose |
|------|---------|
| 9fat | FAT boot partition |
| nvram | NVRAM storage |
| fossil | Fossil filesystem |
| venti | Venti archive |
| swap | Swap space |
| other | Data partitions |

## Detection

1. Look for MBR partition type 0x39
2. Read ASCII table from start of that partition
3. Parse text lines

## Linux Support

Linux kernel has Plan 9 partition support (CONFIG_PLAN9_PARTITION).
Parses the ASCII table to expose subpartitions.

## Historical Note

Plan 9's text-based approach reflects its philosophy of
"everything is a file" and human-readable configuration.
The format is trivially parseable with standard Unix tools.
