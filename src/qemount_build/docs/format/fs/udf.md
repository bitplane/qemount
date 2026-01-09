---
title: UDF
created: 1995
related:
  - format/fs/iso9660
detect:
  - offset: 0x8001
    type: string
    value: "BEA01"
---

# UDF (Universal Disk Format)

UDF was developed by the Optical Storage Technology Association (OSTA) starting
in 1995 as a successor to ISO 9660. It's the standard filesystem for DVDs,
Blu-ray discs, and modern optical media, but also works on hard disks.

## Characteristics

- Read-write capable (unlike ISO 9660)
- Maximum file size: 16 EB (UDF 2.01+)
- Maximum volume size: 2^64 sectors
- Unicode filenames (up to 254 characters)
- Named streams (like NTFS alternate data streams)
- Extended attributes and ACLs
- Hard and symbolic links
- Sparse files

## Structure

- Volume Recognition Sequence at sector 16+ (0x8000+)
- "BEA01" extended area descriptor at offset 0x8001
- "NSR02" or "NSR03" descriptor indicates UDF version
- Anchor Volume Descriptor at sector 256 and N-256
- Partition descriptor defines data area
- File Set Descriptor contains root directory

## Versions

| Version | Year | Features |
|---------|------|----------|
| 1.02 | 1996 | DVD-ROM |
| 1.50 | 1997 | DVD-RAM, VAT for CD-R |
| 2.00 | 1998 | Streaming, DVD-RW |
| 2.01 | 2000 | Large files (>1GB) |
| 2.50 | 2003 | Metadata partition |
| 2.60 | 2005 | Pseudo-overwritable |

## Use Cases

- DVD-Video and DVD-ROM
- Blu-ray discs
- CD-RW and DVD-RW (packet writing)
- Large optical archives
- Cross-platform removable media
