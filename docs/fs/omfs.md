---
title: OMFS
type: fs
created: 2003
related:
  - fs/udf
detect:
  - offset: 0
    type: le32
    value: 0xc2993d87
---

# OMFS (Optimized MPEG File System)

OMFS was developed by Sonic Solutions (later Rovi) for their DVDit and
ReelDVD video authoring products. It's optimized for handling large media
files with minimal fragmentation.

## Characteristics

- Optimized for large sequential files
- Cluster-based allocation
- Extent-based for contiguous storage
- Maximum file size: limited by implementation
- Designed for video editing workflow

## Structure

- Magic 0xC2993D87 at offset 0
- Superblock contains cluster info
- Root block points to filesystem tree
- Extent-based file storage
- Bitmap tracks allocation

## Design Goals

- Minimal fragmentation for video
- Fast sequential read/write
- Efficient for large files
- Simple structure for reliability

## Use Cases

- DVDit Pro authoring
- ReelDVD projects
- Video editing scratch disks
- Legacy Sonic Solutions products

## Linux Support

Linux has read-only OMFS support (fs/omfs/).
Primarily useful for accessing old video project files.

## Historical Note

OMFS was designed when FAT32's 4GB file limit was problematic
for video work. Modern alternatives like exFAT or ext4 have
largely made it obsolete, but Linux support allows recovery
of old video project files.
