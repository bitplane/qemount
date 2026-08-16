---
title: FSD (BBC Micro protected-disc image)
created: 2010s
system: Acorn BBC Micro / Electron
extensions: [".fsd"]
aliases:
  - FSD disk image
  - BBC FSD
related:
  - format/disk/acorn
  - format/fs/adfs
---

# FSD (BBC Micro protected-disc image)

FSD is a disk-image container for preserving copy-protected BBC Micro floppies.
It was devised by an Acorn enthusiast (forum handle billcarr2005) in the early
2010s specifically to capture protection schemes that plain sector dumps such as
`.ssd`/`.dsd` cannot represent, and was used to archive several hundred original
protected titles. It is closely tied to the Intel 8271 floppy disc controller
used in the original BBC Micro, which is the source of the protection effects it
records.

## What it preserves

A standard SSD image stores only the sector payloads in their nominal order. A
protected disc, by contrast, deliberately produces conditions a normal DFS disc
never would: sectors whose recorded ID differs from their logical position,
sectors that report a CRC/data error when read, sectors of unexpected size, and
deleted-data address marks. The disc relies on the loader seeing these exact
read results, so a faithful image has to store the controller's view of every
sector, not just the data.

FSD is, in effect, an SSD enriched with that per-sector detail: each sector is
preceded by its four-byte sector header (track ID, head, sector ID, size code),
the actual stored data length, and an error code. Because the 8271 can report
only one error condition per sector at a time, FSD likewise records a single
error code per sector — which is why it is specific to the 8271 and does not map
cleanly onto the independent error flags of the later WD177x controllers.

## Structure

- A 3-byte ASCII signature `FSD` at the start of the file.
- A short header carrying creator/date and release information, followed by a
  textual disc title.
- A track count, then per-track records. Each track lists its sector count and a
  readable/unreadable flag; each readable sector stores its header fields,
  reported and actual sizes, an error code, and the sector data. Unreadable
  sectors store metadata only, with no data payload.

Common error-code values include `0x00` (OK), `0x0E` (data CRC error) and `0x20`
(deleted data).

## Detection

Two independent sources (the MAME loader and BBC preservation community
documentation) agree that an FSD file begins with the literal ASCII bytes `FSD`
at offset 0.

## References

- MAME floppy loader: [`src/lib/formats/fsd_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/fsd_dsk.cpp)
- [Protected disc image formats (FDI, FSD…) — stardot.org.uk](https://stardot.org.uk/forums/viewtopic.php?t=11703)
- [DDFS File Format, Archiving & Emulators — stardot.org.uk](https://stardot.org.uk/forums/viewtopic.php?t=20187)
- [Disc Filing System — Wikipedia](https://en.wikipedia.org/wiki/Disc_Filing_System)
