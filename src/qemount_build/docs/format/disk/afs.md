---
title: Acorn FileStore (AFS) disk image
created: 1986
system: Acorn FileStore (Econet file server)
extensions: [".adl", ".img"]
aliases:
  - Acorn FileStore image
related:
  - format/disk/acorn
  - format/disk/raw
---

# Acorn FileStore (AFS) disk image

A raw, headerless sector image of a floppy from the Acorn FileStore, Acorn's
first dedicated Econet network file server (the E01, 1986). The FileStore was a
65C102 machine with two 3.5" drives; AFS is its filing system, distinct from the
DFS/ADFS used on the BBC Micro and Electron.

## Geometry

Fixed geometry, MFM with an interleaved layout:

| Property | Value |
|----------|-------|
| Tracks | 80 |
| Sides | 2 |
| Sectors / track | 16 |
| Bytes / sector | 256 |
| Total | 640 KB (3.5" DSDD) |

The image has no header; disks are identified by their sector structure and
size rather than a signature.

## References

- MAME loader: [`src/lib/formats/afs_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/afs_dsk.cpp)
- [Acorn FileStore — Chris's Acorns](http://chrisacorns.computinghistory.org.uk/Network/Pics/Acorn_FileStoreE01.html)
- [Acorn FileStore — The Oddys Website](https://theoddys.com/acorn/acorn_system_filing_systems/econet/acorn_filestore/acorn_filestore.html)
