---
title: FDI (Formatted Disk Image)
created: 2000
system: Multi-platform preservation (Amiga, Apple, Atari, PC, Commodore, etc.)
extensions: [".fdi"]
aliases:
  - Formatted Disk Image
  - Disk2FDI image
related:
  - format/disk/dfi
  - format/disk/86f
  - format/disk/raw
---

# FDI (Formatted Disk Image)

FDI is a system-agnostic floppy disk preservation format published by Vincent
Joguin around 2000 and most associated with the **Disk2FDI** imaging tool, which
reads foreign-format floppies on a standard PC drive. Rather than committing to
one platform's geometry, an FDI file carries a self-describing header and a
per-track directory so that disks from Amiga, Apple, Atari ST, Commodore and
IBM/PC machines can all be wrapped in the same container at a low (track / pulse)
level.

This is the version 2.0 specification. The header opens with a fixed ASCII
signature, followed by creator and comment text, version and geometry fields
(media type covering 8", 5.25", 3.5" and 3" disks, and track density expressed in
TPI from 48 up to 192), and a track table of up to ~180 entries. Each track entry
records a track *type* (blank, Amiga DD/HD, various IBM/PC encodings, Commodore
1541 GCR, Apple DOS variants, etc.) and the size of that track's data, which is
appended after the header. Flags cover write protection and index
synchronisation.

Because each track can be stored at the encoded/flux level with its own type
tag, FDI is a surface-preservation format rather than a plain sector dump — the
track table itself is the navigable structure. MAME's loader currently parses
the header but treats the per-track decoders as unimplemented.

Note: the `.fdi` extension is heavily overloaded. This page is the Joguin
"Formatted Disk Image file" container only. Unrelated formats also use `.fdi`,
including a ZX Spectrum disk image (signature `FDI`) and the Anex86 PC-98 image
format — those are different formats that happen to share the extension.

## Detection

Two independent sources (the MAME loader and the published FDI 2.0 specification,
also reflected in file-signature databases) agree that a v2.0 file begins at
offset 0 with the ASCII string `Formatted Disk Image file` (hex `46 6F 72 6D 61
74 74 65 64 20 44 69 73 6B 20 49 6D 61 67 65 20 66 69 6C 65`). This is the
reliable discriminator from the unrelated `.fdi` formats, whose magics differ.

## References

- MAME source: `src/lib/formats/fdi_dsk.cpp`
  (https://github.com/mamedev/mame/blob/master/src/lib/formats/fdi_dsk.cpp)
- FDI 2.0 specification (Vincent Joguin / Disk2FDI): http://www.oldskool.org/disk2fdi
  and the spec PDF http://www.oldskool.org/disk2fdi/files/FDISPEC.pdf
- FDI file signature reference: https://filext.com/file-extension/FDI
- Archive Team file formats wiki, Disk Image Formats:
  http://fileformats.archiveteam.org/wiki/Disk_Image_Formats
