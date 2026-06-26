---
title: APRIDISK
created: unknown
system: ACT Apricot (UK)
extensions: [".dsk"]
aliases:
  - ACT Apricot disk image
related:
  - format/disk/apricotpc
  - format/fs/fat12
  - format/disk/raw
detect:
  any:
    # ASCII "ACT Apricot disk image" (followed by 0x1A 0x04) at offset 0.
    - offset: 0
      type: string
      value: "ACT Apricot disk image"
---

# APRIDISK

APRIDISK is a self-describing disk-image container for ACT Apricot
microcomputers, distinct from the flat Apricot PC/Xi sector dump. Rather than
storing tracks at fixed offsets, it holds a sequence of typed records — sectors
plus optional comment and creator metadata — so it can represent disks with
missing sectors, deleted sectors, or CRC-error flags faithfully.

The container begins with a fixed-size header followed by variable-length
records. Each record carries a type tag, a compression mode, a header length and
a data length (all little-endian). Sector records add track / head / sector
identifiers and flags; their 512-byte payload may be stored raw or run-length
compressed (a 3-byte count plus a fill byte). The decoded geometry is up to 80
tracks, 2 heads, 18 sectors per track at 512 bytes per sector.

## Detection

Two independent sources agree the file opens with the ASCII signature
`ACT Apricot disk image` followed by the two bytes `0x1A 0x04`, at offset 0.
The header occupies 128 bytes. Record type tags include a magic/sector record,
a comment record and a creator record; compression is selected per record
between an uncompressed and an RLE-compressed mode.

## References

- MAME loader: [`src/lib/formats/apridisk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/apridisk.cpp)
- [ACT/Apricot — Apricot software archiving with APRIDISK](https://actapricot.org/support/apricot_apridisk.html)
