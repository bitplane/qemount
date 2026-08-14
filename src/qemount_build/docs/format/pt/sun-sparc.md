---
title: Sun SPARC disklabel (VTOC8)
created: 1983
related:
  - format/fs/ufs1
  - format/fs/ufs2
detect:
  - offset: 508
    type: be16
    value: 0xDABE
    name: vtoc_magic
---

# Sun SPARC disklabel (VTOC8)

The Sun SPARC disklabel is the big-endian VTOC8 partitioning scheme used by
SunOS and Solaris on SPARC systems. It stores partition information in the
disk label at the start of the disk.

## Characteristics

- Up to 8 partitions (slices)
- Big-endian format
- Partition 2 traditionally represents whole disk
- Disk geometry information included
- Magic 0xDABE at offset 508

This is distinct from the little-endian VTOC16 label used inside an MBR
Solaris partition on x86 systems.

## Structure

**Disk Label (512 bytes)**
```
Offset  Size  Description
0       128   ASCII label (e.g. "GNU Parted Custom cyl...")
128     4     VTOC version
132     16    Volume name
148     2     Number of partitions
...
188     96    VTOC partition info (8 × 12 bytes: tag, flag, start, size)
284     4     VTOC sanity (0x600DDEEE)
...
436     2     Heads (ntrks)
438     2     Sectors per track (nsect)
440     4     Reserved
444     64    Partition table (8 × 8 bytes: start_cyl, num_sectors)
508     2     Magic (0xDABE)
510     2     Checksum
```

**Partition Table Entry (8 bytes at offset 444)**
```
Offset  Size  Description
0       4     Start cylinder (big-endian)
4       4     Number of sectors (big-endian)
```

Actual byte offset = start_cylinder × heads × sectors_per_track × 512

## Partition Tags

| Tag | Description         |
|-----|---------------------|
| 0   | Unassigned          |
| 1   | Boot                |
| 2   | Root                |
| 3   | Swap                |
| 4   | /usr                |
| 5   | Whole disk (backup) |
| 6   | Stand               |
| 7   | /var                |
| 8   | /home               |

## Detection Notes

Look for 0xDABE at offset 508. The VTOC sanity value 0x600DDEEE at offset 284
provides additional confirmation.
