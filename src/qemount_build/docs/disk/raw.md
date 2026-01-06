---
title: Raw Disk Image
created: 1980
related:
  - disk/qcow2
detect: []
---

# Raw Disk Image

A raw disk image is the simplest format - just the bytes as they would appear
on a physical disk, with no container format or metadata. What you see is what
you get.

## Characteristics

- No header or metadata
- No compression
- No encryption
- No snapshots
- File size equals disk size (unless sparse)
- Maximum compatibility
- Direct sector access

## Structure

None. Byte 0 of the file is byte 0 of the disk. The file length determines the
disk size.

## Detection

Raw is the fallback format - if a file doesn't match any known disk image
signature, it's assumed to be raw. Common extensions are `.img`, `.raw`, `.bin`,
and `.iso` (for optical disc images).

## Sparse Files

On filesystems that support it, raw images can be sparse - regions of zeros
aren't physically stored. This makes raw images practical for large disks that
aren't full:

```sh
# Create 100GB sparse image (nearly instant, minimal space)
truncate -s 100G disk.img

# Check actual vs apparent size
ls -lh disk.img    # shows 100G
du -h disk.img     # shows actual space used
```

## Use Cases

- Simple disk dumps (`dd if=/dev/sda of=disk.img`)
- ISO images for optical media
- Maximum performance (no decode overhead)
- Compatibility with any tool
