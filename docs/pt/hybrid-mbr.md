---
title: Hybrid MBR
type: pt
created: 2006
related:
  - pt/mbr
  - pt/gpt
detect:
  - offset: 510
    type: le16
    value: 0xAA55
    then:
      - offset: 0x1C2
        type: u8
        op: noteq
        value: 0xEE
        name: not_protective
      - offset: 512
        type: string
        value: "EFI PART"
        name: has_gpt
---

# Hybrid MBR (GPT + MBR)

A Hybrid MBR is a disk that has both a valid GPT and a non-protective
MBR, allowing the same disk to be booted on both UEFI and BIOS systems.

## Characteristics

- Valid GPT at LBA 1+
- MBR with real partitions (not just protective)
- Up to 3 partitions mirrored in MBR
- Used for dual-boot scenarios
- Created by tools like gdisk

## Structure

```
LBA 0     Hybrid MBR (real partition entries)
LBA 1     GPT Header
LBA 2-33  GPT Partition Entries
...       Partitions
LBA -33   Backup GPT entries
LBA -1    Backup GPT header
```

## MBR Contents

Unlike protective MBR (single 0xEE entry), hybrid MBR has:
- Real partition entries matching some GPT partitions
- Optional 0xEE entry for remaining space
- Boot code that can chainload

## Use Cases

- **Boot Camp**: macOS + Windows on Intel Macs
- **Dual boot**: UEFI Linux + BIOS Windows (or vice versa)
- **Compatibility**: GPT disk accessible to old BIOS tools

## Creating Hybrid MBR

```sh
# Using gdisk
gdisk /dev/sdX
# r (recovery menu)
# h (hybrid MBR)
# Select partitions to include
```

## Risks

- MBR and GPT can become inconsistent
- Some tools only see MBR partitions
- Windows may "fix" the MBR unexpectedly
- Apple diskutil can break it

## Detection

1. Check for 0xAA55 at offset 510
2. Check MBR partition entries are NOT just 0xEE
3. Check for "EFI PART" at offset 512
4. If all true = Hybrid MBR

## Linux Support

Linux handles hybrid MBR by preferring GPT. The MBR
partition entries are typically ignored unless booting
in BIOS mode.
