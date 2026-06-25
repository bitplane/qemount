---
title: MFI — MAME Floppy Image
created: c. 2012
system: MAME / MESS emulator (preservation format)
extensions: [".mfi"]
aliases: [MFI, "MAME Floppy Image", "MESS Floppy Image", MESSFLOPPYIMAGE, MAMEFLOPPYIMAGE]
related:
  - format/disk/hfe
  - format/disk/ipf
  - format/disk/86f
  - format/disk/dfi
  - format/disk/hxcmfm
detect:
  any:
    - offset: 0
      type: string
      value: "MAMEFLOPPYIMAGE"
    - offset: 0
      type: string
      value: "MESSFLOPPYIMAGE"   # legacy MESS releases
---

MFI is the native floppy-image container written by the MAME (and historically
MESS) emulator. Rather than storing decoded sectors, it preserves the low-level
flux transitions of a disk surface, which lets it represent copy-protected,
mixed-density and otherwise irregular media that a plain sector dump cannot. It is
one of the few formats MAME can both read and write, making it MAME's own
preservation target.

The file begins with a fixed header: a 16-byte signature, followed by 32-bit
little-endian fields for cylinder count, head count, form factor and variant. The
top bits of the cylinder count encode the track resolution (whole tracks,
half-tracks or quarter-tracks) so that, for example, Apple-style half-tracking can
be represented. A track-offset table follows the header, and each track's flux
data is stored as an independently zlib-compressed block.

Within a track, flux is encoded as a sequence of 32-bit little-endian cells. The
low 28 bits give the angular position as a delta in units of 1/200,000,000th of a
revolution, and the high 4 bits give the cell type (a flux transition, or a
neutral/damaged/end-of-track marker). This delta-packed angular representation is
what makes MFM/GCR/FM and weak or damaged areas all expressible in one container.

## Detection

The header opens with a 16-byte ASCII signature. Current files use
`MAMEFLOPPYIMAGE`; files written by older MESS releases use the legacy
`MESSFLOPPYIMAGE`. Both forms are recognised on read. This is corroborated by the
MAME source and by independent tooling discussions (Greaseweazle, MAME's floptool
documentation), and the `detect:` rule keys on these two 16-byte signatures.

## References

- MAME source: `src/lib/formats/mfi_dsk.cpp` and `mfi_dsk.h`
  (https://github.com/mamedev/mame/blob/master/src/lib/formats/mfi_dsk.cpp)
- MAME floptool documentation
  (https://docs.mamedev.org/tools/floptool.html)
- Greaseweazle issue #281, "Support MAME's MFI disk image format"
  (https://github.com/keirf/greaseweazle/issues/281)
