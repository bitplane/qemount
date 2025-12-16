---
title: HFS
type: fs
created: 1985
related:
  - fs/hfsplus
  - fs/amiga-ffs
detect:
  - offset: 0x400
    type: be16
    value: 0x4244
    then:
      - offset: 0x40e
        type: be16
        value: 0x0003
      - offset: 0x414
        type: be32
        name: block_size
      - offset: 0x412
        type: be16
        name: block_count
---

# Hierarchical File System (HFS)

HFS was developed by Apple and released in 1985 for the Macintosh. It replaced
the earlier Macintosh File System (MFS) and was the primary Mac filesystem
until HFS+ arrived in 1998. Also known as "Mac OS Standard".

## Characteristics

- 16-bit allocation block addresses (max 65,535 blocks)
- Maximum volume size: ~2GB practical limit
- Maximum file size: ~2GB
- 31-character filenames (Pascal strings)
- Case-insensitive, case-preserving filenames
- Resource and data forks (dual-fork files)
- No journaling
- Creator/type codes for file associations

## Structure

- Volume header at offset 1024 (0x400)
- Signature 0x4244 ("BD" - likely "Big Disk")
- Allocation block bitmap
- B*-tree catalog for file/folder metadata
- B*-tree extents overflow for fragmented files

## Limitations

- No symbolic links
- No hard links
- Path separator is colon (:) not slash
- Poor handling of many small files
- 2GB volume/file size limit

## Legacy

- Superseded by HFS+ in Mac OS 8.1 (1998)
- Read-only support in modern macOS
- Linux supports via hfs module
- Still found on old Mac floppies, CDs, and disk images
