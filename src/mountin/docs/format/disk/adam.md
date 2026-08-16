---
title: Coleco Adam disk image
created: 1983
system: Coleco Adam
extensions: [".dsk"]
related:
  - format/media/adam-ddp
  - format/disk/raw
---

# Coleco Adam disk image

A raw, headerless sector image for Coleco Adam (1983) floppy disks. The Adam's
Elementary Operating System (EOS) treats all storage as a linear sequence of
1 KB blocks across the ADAMnet bus; on a floppy these are held as 512-byte
sectors, with logically consecutive sectors physically interleaved.

## Geometry

Headerless; MAME selects geometry by file size (MFM):

| Size | Tracks | Sides | Sectors | Bytes/sector | Media |
|------|--------|-------|---------|--------------|-------|
| 163,840 | 40 | 1 | 8 | 512 | 5.25" SSDD |
| 327,680 | 40 | 2 | 8 | 512 | 5.25" DSDD |
| 737,280 | 80 | 2 | 9 | 512 | 3.5" DSDD |
| 1,474,560 | 80 | 2 | 18 | 512 | 3.5" DSHD |

## References

- MAME loader: [`src/lib/formats/adam_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/adam_dsk.cpp)
- [Coleco Adam — Wikipedia](https://en.wikipedia.org/wiki/Coleco_Adam)
