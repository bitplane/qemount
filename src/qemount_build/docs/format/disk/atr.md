---
title: Atari 8-bit disk image (ATR / XFD)
created: unknown
system: Atari 8-bit (400/800/XL/XE)
extensions: [".atr", ".xfd", ".dsk"]
aliases:
  - Atari floppy disk image
  - NICKATARI image
  - Xformer disk
related:
  - format/fs/atari-dos
  - format/disk/raw
detect:
  any:
    # Little-endian magic word 0x0296 (bytes 96 02) at offset 0, the byte sum
    # of "NICKATARI". XFD/DSK are headerless and have no signature.
    - offset: 0
      type: string
      value: [0x96, 0x02]
---

# Atari 8-bit disk image (ATR / XFD)

Sector images for the Atari 8-bit computer line (400/800 and the later XL/XE
machines, from 1979 onward) and their SIO disk drives such as the 810 and 1050.
These are the everyday disk-dump formats used by Atari emulators and SIO2PC-style
tools. MAME accepts the family under the `atr`, `xfd` and `dsk` extensions as a
single "Atari floppy disk image" loader.

## Variants

| Variant | Ext | Header | Layout |
|---------|-----|--------|--------|
| ATR | `.atr` | 16-byte header | header followed by sector data |
| XFD | `.xfd` | none | raw sector dump (Xformer) |
| DSK | `.dsk` | none | raw sector dump |

After any header, the body is a straight sequence of sector contents: sector 1,
then sector 2, and so on. Typical geometries are single density (128-byte
sectors, ~90 KB) and double/enhanced density (256-byte sectors), with the
booting first three sectors conventionally kept at 128 bytes.

## ATR header

The ATR variant carries a 16-byte header. The first 16-bit word is the
identifier `0x0296` — the byte sum of the ASCII string `NICKATARI`, after the
format's author. The header also records the image size in 16-byte
"paragraphs", the sector size (128 or 256 bytes), and a handful of flag and
spare bytes. XFD and DSK images omit this header and are pure sector dumps,
identified only by size and geometry.

## Detection

The ATR header begins with the little-endian magic word `0x0296` (bytes
`96 02`), derived from the string `NICKATARI`. Multiple independent format
references agree on this signature. XFD and DSK images have no signature.

## References

- MAME loader: [`src/lib/formats/atari_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/atari_dsk.cpp)
- [ATR — Just Solve the File Format Problem](http://fileformats.archiveteam.org/wiki/ATR)
- [Atari Disk Image FAQ — AtariMax](https://www.atarimax.com/ape/docs/DiskImageFAQ/)
- [Atari 8-bit FAQ: .DCM, .ATR and .XFD formats](https://atarimuseum.ctrl-alt-rees.com/archives/atari-8-bit-faq/faq-doc-27.html)
