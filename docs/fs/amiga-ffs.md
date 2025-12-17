---
title: Amiga FFS
created: 1988
discontinued: 1994
related:
  - fs/amiga-ofs
detect:
  - type: string
    value: "DOS"
    then:
      - offset: 3
        type: u8
        value: 1
---

# Amiga Fast File System

The Fast File System (FFS), also known as DOS1, was introduced with AmigaOS 1.3
in 1988 as an improvement over the original OFS. It's identified by the "DOS\1"
signature in the boot block.

## Characteristics

- Full 512 bytes usable per data block (no per-block headers)
- Significantly faster than OFS, especially on hard disks
- Root block at physical middle of disk
- Case-insensitive filenames (up to 30 characters)
- No journaling - corruption possible on unclean unmount
- Backward compatible reading of OFS disks

## Structure

- Boot block at blocks 0-1 (contains "DOS\1" identifier)
- Root block at middle of disk (block 880 for DD, 1760 for HD floppies)
- Bitmap blocks track free/used blocks
- File header blocks contain metadata and data block pointers
- Data blocks are pure data (no headers)

## Variants

| ID   | Name | Description |
|------|------|-------------|
| DOS1 | FFS | Fast File System |
| DOS3 | FFS-INTL | International (non-ASCII) filenames |
| DOS5 | FFS-DC | Directory cache for faster listings |
| DOS7 | FFS-INTL-DC | International + directory cache |

## Improvements over OFS

- ~7% more disk space (no 24-byte headers per data block)
- Faster file operations
- Better suited for hard disk use
- Became the standard Amiga filesystem
