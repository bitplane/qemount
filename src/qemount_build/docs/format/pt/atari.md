---
title: Atari AHDI
created: 1985
related:
  - format/pt/mbr
detect:
  - offset: 0x1c6
    type: byte
    mask: 0x01
    value: 0x01
    name: part0_flag_active
    then:
      - offset: 0x1c7
        type: ascii
        length: 3
        value: "^[A-Za-z0-9]{3}$"
        name: part0_id
        then:
          # First partition starts near beginning (after boot sector)
          - offset: 0x1ca
            type: be32
            op: ">"
            value: 0
            name: part0_start_nonzero
            then:
              - offset: 0x1ca
                type: be32
                op: "<"
                value: 0x100
                name: part0_start_near_beginning
                then:
                  # Partition size must be non-zero and reasonable (<1GB)
                  - offset: 0x1ce
                    type: be32
                    op: ">"
                    value: 0
                    name: part0_size_nonzero
                    then:
                      - offset: 0x1ce
                        type: be32
                        op: "<"
                        value: 0x200000
                        name: part0_size_reasonable
---

# Atari AHDI (Atari Hard Disk Interface)

AHDI is the partitioning scheme used by Atari ST/TT/Falcon computers.
It predates and differs from PC MBR partitioning.

## Characteristics

- Up to 4 primary partitions in rootsector
- Up to 8 ICD/Supra partitions (alternative scheme)
- Extended partitions via XGM type
- Big-endian format (68000 CPU)
- Stored in sector 0

## Rootsector Structure (512 bytes)

Based on Linux kernel `block/partitions/atari.h`:

```
Offset  Size  Description
0x000   0x156 Boot code / unused (342 bytes)
0x156   96    ICD partition table (8 × 12 bytes)
0x1b6   12    Unused
0x1c2   4     hd_siz - disk size in sectors
0x1c6   48    Primary partition table (4 × 12 bytes)
0x1f6   4     bsl_st - bad sector list start
0x1fa   4     bsl_cnt - bad sector list count
0x1fe   2     Checksum
```

## Partition Entry (12 bytes)

```
Offset  Size  Description
0       1     Flags (bit 0 = active, bit 7 = bootable)
1       3     Partition ID (ASCII, e.g., "GEM", "BGM")
4       4     Start sector (big-endian)
8       4     Sector count (big-endian)
```

## Partition Types

| ID  | Description               |
|-----|---------------------------|
| GEM | GEM/TOS partition (<16MB) |
| BGM | Big GEM (>16MB)           |
| XGM | Extended partition chain  |
| RAW | Raw partition             |
| LNX | Linux                     |
| SWP | Linux swap                |
| MIX | Minix                     |

## Detection

No magic number. Linux kernel validates by checking:
1. At least one primary partition has flag bit 0 set
2. Partition ID contains 3 alphanumeric characters
3. Start + size does not exceed disk size

## Extended Partitions (XGM)

XGM entries form a linked list similar to MBR extended partitions.
Each XGM sector contains partition entries pointing to the next XGM.

## ICD/Supra Partitions

Alternative scheme at offset 0x156 with 8 partition slots.
Only used if no XGM extended partitions are present.
