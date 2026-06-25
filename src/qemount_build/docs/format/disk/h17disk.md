---
title: H17Disk (Heathkit H-17 hard-sectored disk image)
created: unknown
system: Heathkit/Heath-Zenith H8 and H-89 (HDOS / CP/M)
extensions: [".h17disk"]
aliases:
  - H17D
  - Heath H17 hard-sectored image
related:
  - format/media/h8-cas
---

# H17Disk (Heathkit H-17 hard-sectored disk image)

A tagged container format for preserving images of the hard-sectored 5.25"
floppies used by the Heathkit H-17 disk system on the H8 and H-89 (Z-89)
computers. Unlike the older raw `H8D` dump (which stores only the user data and
discards the on-disk sector headers), H17Disk wraps the captured data in a block
structure that also keeps the sector header, sync and checksum bytes, so a disk
can be reconstructed faithfully.

## System and era

The H-17 was Heath's 5.25" floppy subsystem, introduced around 1979 for the H8
and bundled (as the H-88-1 controller) with the H-89 all-in-one terminal-style
machine. Its disks are **hard-sectored**: the diskette itself carries an index
hole plus ten beginning-of-sector holes (eleven holes total), and the controller
relies on those holes rather than software-located sector marks. The standard
disk is single-sided, 40 tracks, 10 sectors per track, 256 data bytes per
sector, FM encoding — roughly 100 KB (102,400 bytes) of user data. Drives and
later controllers also allowed double-sided and 80-track variants.

The H17Disk container itself is a modern preservation format defined by Mark
Garlanger and circulated in the SEBHC (Society of Eight-Bit Heath Computers)
community; the published specification is a draft revised through the late 2010s
and early 2020s.

## Structure

The file is a sequence of tagged blocks. Each block begins with a 4-byte
identifier and a length field, followed by the block payload, so a reader can
walk the file block by block:

| Block | Purpose |
|-------|---------|
| `H17D` | File signature / magic at offset 0 |
| `DskF` | Disk format: head count, track count |
| `SecM` | Sector metadata / locations |
| `H8DB` | Data container holding the sector blocks |
| `Parm`, `Date`, `Imgr`, `Prog` | Optional metadata (parameters, capture date, imager, program) |

Within the data, each sector retains its full on-disk framing: sync bytes,
volume/track/sector header, the 256 data bytes, and a checksum. MAME's loader
reads these images but does not write them.

## Detection

Both MAME's parser and the published H17Disk specification agree that the file
begins with the four ASCII bytes `H17D` (`0x48 0x31 0x37 0x44`), used as the
format's magic number. The block-tagged layout means there is real navigable
structure beyond the signature.

## References

- MAME loader: [`src/lib/formats/h17disk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/h17disk.cpp)
- [H17Disk — New H17 Hard-sectored Disk Image (draft spec, M. Garlanger)](https://heathkit.garlanger.com/diskformats/H17Disk-draft.pdf)
- [Heathkit Floppy Disk Formats](https://heathkit.garlanger.com/diskformats/) (hard-sectored geometry, H8D vs H17Disk)
- [Heath H-89 Computers](https://heathkit.garlanger.com/hardware/systems/H89/)
