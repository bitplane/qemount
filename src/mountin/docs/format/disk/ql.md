---
title: Sinclair QL floppy image
created: 1984
system: Sinclair QL (Motorola 68008)
extensions: [".dsk", ".img"]
aliases:
  - QL DSDD
  - ql_dsk
  - QDOS disk
---

# Sinclair QL floppy image

A raw, headerless sector image of a 3.5" floppy as used by the **Sinclair QL**
(1984), a Motorola 68008-based British home/business machine running the QDOS
operating system. The QL shipped with Microdrive tape cartridges, but disk
interfaces (Miracle, CST, and others) added WD177x-controlled floppy drives,
and those disks are what this format captures. The image is a plain dump of the
disk's sectors with no container header.

The on-disk filesystem is **QDOS** (sometimes called the QL/Level-2 filesystem):
the first block holds a sector/block map, an array of three-byte records — one
per logical block — encoding a file number and a sequence number. That
filesystem is not yet catalogued separately; see *References* for a description.

## Geometry

MAME's loader (derived from `wd177x_format`) recognises four MFM geometries,
all 3.5", 80 cylinders, double-sided:

| Variant | Sectors/track | Bytes/sector | Total |
|---------|---------------|--------------|-------|
| QDOS (native) | 5 | 1024 | 819,200 bytes (800 KB) |
| DSDD | 9 | 512 | 737,280 bytes (720 KB) |
| DSHD | 18 | 512 | 1,474,560 bytes (1.44 MB) |
| DSED | 40 | 512 | 3,276,800 bytes (3.2 MB) |

The 720 KB, 1.44 MB and ED geometries mirror PC-compatible DD/HD/ED disks; the
800 KB 5×1024 layout is the QL's own native format. Independent QL documentation
describes the extended-density disks as having 1024-byte sectors, whereas MAME
encodes its ED variant with 512-byte sectors — a minor discrepancy worth noting
when identifying 3.2 MB images. The format has no magic; geometry plus the
`.dsk`/`.img` extension are the only identifiers, so there is no Detection
section. MAME's source flags its gap values as unverified.

## References

- MAME loader: [`src/lib/formats/ql_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/ql_dsk.cpp)
- [Sinclair QL floppy disk file system format — soulsphere.org](https://soulsphere.org/hacks/ql/fs.html)
- [Identifying floppy disk images — The Sinclair QL Forum](https://theqlforum.com/viewtopic.php?t=1978)
- [Support for Sinclair QL and Thor discs — Greaseweazle issue #391](https://github.com/keirf/greaseweazle/issues/391)
