---
title: HxC MFM floppy image
created: 2006
system: HxC Floppy Emulator (cross-platform floppy preservation)
extensions: [".mfm"]
aliases:
  - HXCMFM
  - HxC MFM IMG
  - MFM_IMG
related:
  - format/disk/hfe
  - format/disk/ipf
  - format/disk/imd
---

# HxC MFM floppy image

The `.mfm` image is one of the native container formats produced by the HxC
Floppy Emulator toolkit (by Jean-François Del Nero, "jfdelnero" / hxc2001). The
HxC project replaces a real floppy drive with an SD-card or USB device that
streams stored track data to vintage hardware, and its software converts between
dozens of disk-image formats. The MFM container holds the already-MFM-encoded
bit-cell stream for each track, rather than decoded sectors, so it preserves the
on-track layout of arbitrary (including non-standard or copy-protected) disks.

It is the simpler, flat sibling of the better-known HxC **HFE** format. Where
HFE interleaves both sides' bitstreams and carries a richer header, the MFM
container stores a fixed file header followed by a flat track-descriptor table
and then the raw MFM track data those descriptors point at.

## Structure

A fixed header sits at offset 0:

- a 7-byte name field carrying the ASCII signature `HXCMFM`,
- number of tracks (16-bit), number of sides (8-bit),
- floppy RPM (16-bit) and bit rate (16-bit),
- an interface-type byte,
- a 32-bit offset to the track-descriptor list.

Each track descriptor in that list records the track number (16-bit), side
number (8-bit), the MFM data size (32-bit) and a 32-bit absolute offset to that
track's MFM bit-cell data elsewhere in the file. The descriptors let the loader
locate every (track, side) stream independently, so the data blocks need not be
contiguous or ordered.

## Detection

Both the MAME loader and the upstream HxC `mfm_loader.c` identify the format by
the 6-byte ASCII string `HXCMFM` at the very start of the file (stored in the
header's 7-byte name field). The two implementations agree on this signature.

## References

- MAME loader: [`src/lib/formats/hxcmfm_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/hxcmfm_dsk.cpp)
- HxC Floppy Emulator source, MFM loader: [`libhxcfe/sources/loaders/mfm_loader/mfm_loader.c`](https://github.com/jfdelnero/HxCFloppyEmulator/blob/master/libhxcfe/sources/loaders/mfm_loader/mfm_loader.c)
- [HxC Floppy Emulator project](https://hxc2001.com/floppy_drive_emulator/)
- [HFE (HxC Floppy Emulator) file format — Library of Congress](https://www.loc.gov/preservation/digital/formats/fdd/fdd000613.shtml)
