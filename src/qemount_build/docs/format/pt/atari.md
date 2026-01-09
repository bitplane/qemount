---
title: Atari AHDI
created: 1985
related:
  - format/pt/mbr
detect:
  - offset: 0x1C6
    type: be32
    name: partition_start
    op: nonzero
    then:
      - offset: 0x1C2
        type: string
        name: partition_id
---

# Atari AHDI (Atari Hard Disk Interface)

AHDI is the partitioning scheme used by Atari ST/TT/Falcon computers.
It predates and differs from PC MBR partitioning.

## Characteristics

- Up to 4 primary partitions in base table
- Extended partitions via XGM type
- Big-endian format
- Stored in first sector
- Similar layout to MBR but different semantics

## Structure

```
Offset  Size  Description
0       2     Branch instruction (boot code)
2       6     OEM data
8       3     Serial number
11      2     Bytes per sector
13      2     Reserved
15      2     Reserved
...
0x1C2   12    Partition entry 1
0x1CE   12    Partition entry 2
0x1DA   12    Partition entry 3
0x1E6   12    Partition entry 4
0x1F2   4     Bad sector count
0x1F6   ...   Bad sector list
0x1FE   2     Checksum
```

## Partition Entry (12 bytes)

```
Offset  Size  Description
0       1     Flags (0x01 = exists, 0x80 = bootable)
1       3     Partition ID (ASCII, e.g., "GEM", "BGM")
4       4     Start sector
8       4     Sector count
```

## Partition Types

| ID | Description |
|----|-------------|
| GEM | GEM/TOS partition (<16MB) |
| BGM | Big GEM (>16MB) |
| XGM | Extended partition |
| RAW | Raw partition |
| LNX | Linux |
| SWP | Linux swap |
| MIX | Minix |

## Detection Notes

No definitive magic number. Check for valid partition IDs and structure.
The checksum at 0x1FE should validate (sum of all words = 0x1234).
