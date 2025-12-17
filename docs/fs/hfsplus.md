---
title: HFS+
type: fs
created: 1998
discontinued: 2017
related:
  - fs/hfs
  - fs/apfs
detect:
  any:
    - offset: 0x400
      type: be16
      value: 0x482B
      then:
        - offset: 0x402
          type: be16
          name: version
        - offset: 0x428
          type: be32
          name: block_size
        - offset: 0x42c
          type: be32
          name: total_blocks
    - offset: 0x400
      type: be16
      value: 0x4858
---

# HFS Plus

HFS+ (also HFS Plus or Mac OS Extended) was introduced with Mac OS 8.1 in 1998
as a major improvement over HFS. It remained Apple's primary filesystem until
APFS replaced it in 2017, and is still used for some purposes.

## Characteristics

- 32-bit allocation block addresses
- Maximum volume size: 8 EiB (theoretical)
- Maximum file size: 8 EiB (theoretical)
- 255-character Unicode filenames (UTF-16)
- Journaling (added in Mac OS X 10.2.2)
- Hard links and symbolic links
- Nanosecond timestamps
- Access control lists (ACLs)
- Compression (HFS+ Compression, Mac OS X 10.6+)

## Structure

- Volume header at offset 1024 (0x400)
- Signature 0x482B ("H+") or 0x4858 ("HX" for case-sensitive HFSX)
- B-tree catalog file
- B-tree extents overflow file
- B-tree attributes file (extended attributes)
- Allocation file (bitmap)

## Variants

| Signature | Name | Description |
|-----------|------|-------------|
| 0x482B | HFS+ | Standard, case-insensitive |
| 0x4858 | HFSX | Case-sensitive variant |

## Journaling

When journaled, writes go to a journal file before being committed. The journal
can be stored on the same volume or external. Enabled by default since Mac OS X
10.3.

## Legacy

- Superseded by APFS (2017) for SSDs and modern Macs
- Still used for mechanical drives and Time Machine on HDD
- Linux supports via hfsplus module (limited write support)
