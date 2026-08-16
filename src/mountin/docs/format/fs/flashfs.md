---
title: FlashFS (Plan 9)
related:
  - format/fs/paqfs
  - format/fs/sacfs
detect:
  - offset: 0
    type: string
    value: ROO0
---

# Plan 9 FlashFS

FlashFS is a small journal-based filesystem designed for erasable flash
devices. It is unrelated to the Linux JFFS family. The 9front `mkflashfs` and
`flashfs` programs can create and serve the format in an ordinary file as well
as on flash hardware.

## Structure

An image is divided into fixed-size sectors, 4096 bytes by default. The first
four bytes of a valid sector header are `ROO0`: `ROO` is the format signature
and the final byte is the on-disk version. Variable-width three-byte fields in
the header identify the sector sequence and journal position.

The remaining space holds journal records for directory and file creation,
metadata changes, removal, writes, truncation and summary information. The
formatter initializes headers in the first and final sectors and erases the
intermediate sectors; normal filesystem activity populates the journal.

## References

- [flashfs(4)](http://man.9front.org/4/flashfs)
- [mkflashfs(8)](http://man.9front.org/8/mkflashfs)

