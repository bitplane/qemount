---
title: Camputers Lynx disk image (LDF)
created: unknown
system: Camputers Lynx (UK, 1983)
extensions: [".ldf"]
aliases:
  - Lynx disk image
  - PALE LDF
related:
  - format/media/camplynx-tap
  - format/disk/raw
---

# Camputers Lynx disk image (LDF)

A raw, headerless floppy image for the Camputers Lynx, the British Z80 home
computer of 1983. The `.ldf` extension is the convention used by the PALE
emulator. There is no inter-sector metadata: the file is simply each 512-byte
sector dumped in track-then-side order.

## Geometry

The image carries no header or signature. MAME selects geometry by file size,
supporting two configurations (parameters noted in the MAME source as derived by
inspection, since the disk system is largely undocumented):

| Capacity | Tracks | Sides | Sectors | Bytes/sector | Media |
|----------|--------|-------|---------|--------------|-------|
| 200 KB | 40 | 1 | 10 | 512 | 5.25" SS DD |
| 800 KB | 80 | 2 | 10 | 512 | 5.25" DS QD |

## References

- MAME loader: [`src/lib/formats/camplynx_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/camplynx_dsk.cpp)
- [Jynx — Camputers Lynx emulator (GitHub)](https://github.com/jonathan-markland/Jynx)
- [PALE Lynx Emulator](http://www.russelldavis.org/CamputersLynx/PALE/)
- [Camputers Lynx — RetroBat Wiki](https://wiki.retrobat.org/systems-and-emulators/supported-game-systems/home-computer/camputers-lynx)
