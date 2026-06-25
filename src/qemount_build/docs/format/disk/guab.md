---
title: JPM "Give Us A Break" disk image
created: 1986
system: JPM System 5 arcade hardware (68000)
extensions: [".dsk"]
aliases:
  - guab
  - JPM System 5 disk image
related:
  - format/disk/raw
---

# JPM "Give Us A Break" disk image

A decoded sector image of the 3.5-inch floppy used by JPM's "Give Us A Break"
(1986), a coin-operated trivia/quiz game based on the British TV show and one of
the titles running on JPM's 68000-based System 5 arcade hardware. The machine
loads its game data from disk through a Western Digital WD177x-type floppy
controller, and the image is a flat dump of that disk's sectors.

## Geometry

| Property | Value |
|----------|-------|
| Form factor | 3.5-inch double-sided |
| Tracks | 80 per side |
| Heads | 2 |
| Sectors / track | 18 |
| Sector size | 256 bytes |
| Total | 80 × 2 × 18 × 256 = 737,280 bytes (720 KB) |
| Encoding | MFM, double density (WD177x) |

MAME's loader derives from its generic WD177x format helper and lays the disk out
with the geometry above (its gap sizes are marked "unverified"). The image is
headerless — it carries no signature and is identified by geometry, not magic —
so it cannot be told apart from other raw `.dsk` dumps by its first bytes. The
distinctive part is the 18 × 256-byte sector layout per track rather than the more
common 9 × 512 of a PC 720 KB disk, even though both come to the same total size.

## References

- MAME source: [`src/lib/formats/guab_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/guab_dsk.cpp)
  — name `"guab"`, extension `dsk`, WD177x MFM, 80 tracks, 2 heads,
  18 × 256-byte sectors per track.
- MAME driver: [`src/mame/jpm/guab.cpp`](https://github.com/mamedev/mame/blob/master/src/mame/jpm/guab.cpp)
- [Give us a Break — MAME machine (Arcade Database)](http://adb.arcadeitalia.net/dettaglio_mame.php?game_name=guab&lang=en)
