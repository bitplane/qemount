---
title: DFI (DiscFerret flux image)
created: unknown
system: DiscFerret (multi-platform flux capture hardware)
extensions: [".dfi"]
aliases: [DiscFerret flux dump]
related:
  - format/disk/ipf
  - format/disk/86f
  - format/disk/raw
detect:
  any:
    - offset: 0
      type: string
      value: "DFE2"   # new-style
    - offset: 0
      type: string
      value: "DFER"   # older revision
---

# DFI (DiscFerret flux image)

DFI is the raw flux-capture format produced by the DiscFerret, an open
hardware controller for archiving and analysing magnetic floppy media. Like
other flux-level images it does not store decoded sectors; it records the
stream of magnetic flux transitions read off the surface, so the decoding
(FM/MFM/GCR, copy protection, weak bits) can be performed in software after the
fact. It belongs alongside flux/preservation disk images such as IPF and 86F.

## Structure

The file opens with a 4-byte ASCII magic, followed by a series of disc sample
blocks, one per captured track/revolution. Each block is introduced by a
10-byte big-endian header carrying the cylinder (track) number, the head
number, an optional sector field (used only for hard-sectored media) and the
length in bytes of the flux data that follows.

The flux data itself is a byte stream of timing deltas. A value of `0x7F`
represents a "no transition yet" carry that accumulates into the next real
transition; the high bit (`0x80`) marks an index pulse; ordinary values encode
the interval since the previous transition. Captures may contain several
revolutions of the same track. MAME rescales the raw counts from the capture
clock (inferred as roughly 25, 50 or 100 MHz from the index timing) onto its
internal 200 MHz flux time base.

## Detection

The format is identified by a 4-byte signature at offset 0. New-style images
begin with `DFE2`; an older revision used `DFER`, which current tooling
recognises but no longer accepts. Both MAME and the DiscFerret project's own
format notes describe these two magics.

## References

- MAME loader: [`src/lib/formats/dfi_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/dfi_dsk.cpp)
- [DFI image format — DiscFerret wiki](https://www.discferret.com/wiki/DFI_image_format)
- [floptool — MAME documentation](https://docs.mamedev.org/tools/floptool.html)
