---
title: SCL (Sinclair TR-DOS)
created: 1990s
related:
  - format/disk/trd
  - format/disk/raw
detect:
  any:
    - offset: 0
      type: string
      value: "SINCLAIR"
---

# SCL (Sinclair TR-DOS)

Compact floppy image format for the ZX Spectrum Beta Disk Interface / TR-DOS.
Rather than a full disk image, SCL stores only the TR-DOS catalogue entries and
the sectors actually used by each file. It expands to a standard 640K TRD disk
image (DS80) by laying the files back onto an otherwise-empty TR-DOS disk.

## Background

TR-DOS is the disk operating system of the Technology Research Beta Disk
Interface, the dominant floppy system for the ZX Spectrum. A native TR-DOS disk
(TRD) is a raw track-by-track dump and is mostly empty space on a typical disk.
SCL was created for BBS and modem distribution: by storing only file headers and
occupied sectors, it is far smaller than a TRD and trivial to reconstruct. It is
the most common interchange format for Spectrum disk software.

## File Structure

```
+-----------------------------+
| Signature (8 bytes)         |  "SINCLAIR"
+-----------------------------+
| File count (1 byte)         |  0..128
+-----------------------------+
| Directory entry 0 (14 bytes)|  filename + type + params + sector count
+-----------------------------+
| Directory entry 1           |
+-----------------------------+
| ...                         |  one per file
+-----------------------------+
| File 0 data                 |  sector_count x 256 bytes
+-----------------------------+
| File 1 data                 |
+-----------------------------+
| ...                         |
+-----------------------------+
| Checksum (4 bytes)          |  sum of all preceding bytes (often ignored)
+-----------------------------+
```

## Header (9 bytes)

| Offset | Size | Description |
|--------|------|-------------|
| 0 | 8 | Signature "SINCLAIR" |
| 8 | 1 | Number of files (0-128) |

## Directory Entry (14 bytes)

| Offset | Size | Description |
|--------|------|-------------|
| 0 | 8 | Filename (space-padded) |
| 8 | 1 | File type ('B' Basic, 'C' Code, 'D' Data, '#' Sequential) |
| 9 | 2 | Parameter 1 (start address for B/C) |
| 11 | 2 | Parameter 2 (length in bytes) |
| 13 | 1 | Length in sectors |

File data blocks follow the directory in order, each occupying
`sector_count x 256` bytes.

## Output

Reconstructs a raw TRD disk image with DS80 geometry:

| Property | Value |
|----------|-------|
| Tracks | 80 |
| Sides | 2 |
| Sectors / track | 16 |
| Bytes / sector | 256 |
| Total | 640 KB |
| Disk type | 0x16 (DS80) |

Logical tracks are side-interleaved (logical 0 = side 0/track 0, logical 1 =
side 1/track 0, ...). The expander writes the directory back into track 0 and
appends each file's sectors sequentially, updating the TR-DOS system sector with
the file count and the first-free-sector pointer. The resulting TRD contains a
TR-DOS filesystem.

## Detection

Check for the "SINCLAIR" signature at offset 0.

## References

- [MAME SCL support (PR #15567)](https://github.com/mamedev/mame/pull/15567) - reference implementation
- [TR-DOS / TRD format](http://www.zx-modules.de/fileformats/trdformat.html)
- [Archive Team wiki - SCL](http://fileformats.archiveteam.org/wiki/SCL)
