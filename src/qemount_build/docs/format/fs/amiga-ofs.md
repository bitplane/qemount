---
title: Amiga OFS
created: 1985
discontinued: 1988
related:
  - format/fs/amiga-ffs
detect:
  - type: string
    value: "DOS"
    then:
      - offset: 3
        type: u8
        value: 0
---

# Amiga Old File System

The Original File System (OFS), also known as DOS0, was the first filesystem
used by AmigaOS. Released with the Amiga 1000 in 1985, it was designed for
floppy disks and is identified by the "DOS\0" signature in the boot block.

## Characteristics

- 488 bytes usable per 512-byte block (24 bytes for header/checksum)
- Checksum validation on every block
- Root block at physical middle of disk (block 880 for DD floppies)
- Case-insensitive filenames (up to 30 characters)
- No journaling - corruption possible on unclean unmount
- Supports both floppy and hard disk

## Structure

- Boot block at blocks 0-1 (contains "DOS\0" identifier)
- Root block at middle of disk
- Bitmap blocks track free/used blocks
- File header blocks contain file metadata
- Data blocks store file content with headers

## Variants

| ID   | Name | Description |
|------|------|-------------|
| DOS0 | OFS | Original File System |
| DOS2 | OFS-INTL | International (non-ASCII) filenames |
| DOS4 | OFS-DC | Directory cache for faster listings |
| DOS6 | OFS-INTL-DC | International + directory cache |

## Limitations

- Inefficient for hard disks due to per-block headers
- Slower than FFS due to checksum overhead
- Largely replaced by FFS (DOS1) for hard disk use
