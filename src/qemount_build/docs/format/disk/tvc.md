---
title: Videoton TVC disk image
created: 1985
system: Videoton TV-Computer (TVC)
extensions: [".dsk", ".img"]
aliases:
  - TVC HBF disk
  - TV-Computer disk
related:
  - format/media/tvc-cas
---

# Videoton TVC disk image

This is the floppy-disk image format for the Videoton TV-Computer (TVC), a
Z80-based Hungarian home computer of the mid-1980s. Disk support on the TVC was
provided by the HBF floppy controller cartridge (and later reproductions such as
HBF-2), which used a WD177x-family controller; MAME labels this loader the
"Videoton TVC HBF disk image".

The image is a raw, headerless sector dump — there is no magic signature. It is
identified by its geometry, which MAME and community sources describe as standard
double-density MFM layouts practically identical to contemporary MSX/MS-DOS
disks:

- **720 KB**: 80 tracks, 2 heads, 9 sectors per track, 512-byte sectors (double
  sided)
- **360 KB**: 80 tracks, 1 head, 9 sectors per track, 512-byte sectors (single
  sided)

Because the format carries no header, it cannot be distinguished from other raw
9-sector/512-byte images by content alone; identification relies on context or
the on-disk filesystem rather than a signature. Programs distributed on cassette
use a separate format — see [Videoton TVC cassette](../media/tvc-cas.md).

## References

- MAME loader: [`src/lib/formats/tvc_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/tvc_dsk.cpp)
- [TVC — VIDEOTON TV-Computer (project site, English)](http://tvc.homeserver.hu/html/inenglish.html)
- [Videoton TV-Computer SD adapter notes (disk format description)](https://szergitata.blog.hu/2016/11/17/videoton_tv_computer_tvc_sd_adapter_dual_verzio)
