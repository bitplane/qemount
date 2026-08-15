---
title: UEF (Unified Emulator Format)
created: 2001
system: Acorn BBC Micro / Electron / Atom
extensions: [".uef"]
aliases:
  - Unified Emulator Format
related:
  - format/disk/acorn
  - format/fs/adfs
---

# UEF (Unified Emulator Format)

UEF (Unified Emulator Format) is a container format used by emulators of Acorn's
8-bit machines — chiefly the BBC Micro, Acorn Electron and Atom — to store
cassette tapes, and (in its broader specification) ROMs, disc images and machine
snapshots. It was developed within the late-1990s/early-2000s Acorn emulation
scene (the tape-signal work is generally credited to Thomas Harte) to hold
accurate copies of Acorn, CUTS and BASICODE cassette signals. In practice the
overwhelmingly common use is tape preservation, which is what MAME's loader
implements.

This is a **knowledge-only** media entry: it encodes a tape signal as a chunked
stream, not a mountable filesystem. It is catalogued for identification and
cross-reference; no driver is planned. Acorn *disk* and *filesystem* layouts are
covered separately under [Acorn disk image](../disk/acorn.md) and
[ADFS](../fs/adfs.md).

## Structure

A UEF file is a 12-byte preamble — the 10-byte magic string (below) plus a
two-byte UEF version number — followed by a sequence of chunks. Each chunk has a
2-byte little-endian ID, a 4-byte little-endian length, and a body. Tape-relevant
chunk IDs handled by MAME include:

- 0x0100 implicit-format data block; 0x0104 defined-format data block; 0x0102
  explicit (raw) tape data
- 0x0110 carrier tone; 0x0112 integer gap (silence); 0x0116 floating-point gap
- 0x0117 baud-rate change (300 or 1200 baud)

The whole file, header included, may optionally be gzip-compressed. A reader
distinguishes the two cases by inspecting the first bytes: an uncompressed UEF
starts with the `UEF File!` magic, while a compressed one starts with the gzip
magic 0x1F 0x8B and must be inflated before the chunk stream can be parsed. MAME
detects this and decompresses with zlib as needed.

## Detection

Independent sources agree that an uncompressed UEF file begins with the ten bytes
`UEF File!` followed by a single null terminator (`55 45 46 20 46 69 6C 65 21
00`), after which come the two version bytes. Both the MAME loader and the
published UEF specification (as summarised by Wikipedia and the ElectrEm/mdfs
spec drafts) describe this header. Because the file may instead be gzip-wrapped,
a UEF can alternatively begin with the gzip signature 0x1F 0x8B.

## References

- MAME loader: [`src/lib/formats/uef_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/uef_cas.cpp)
- [Unified Emulator Format — Wikipedia](https://en.wikipedia.org/wiki/Unified_Emulator_Format)
- [UEF File Format Draft Specs 0.10 — mdfs.net](https://mdfs.net/Docs/Comp/BBC/FileFormat/UEFSpecs.htm)
