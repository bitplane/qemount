---
title: MSX CAS Cassette Image
created: unknown
system: MSX
extensions: [".cas"]
aliases: [CAS, fMSX cassette, fmsx_cas]
related:
  - format/disk/dmk
  - format/disk/msx
---

The CAS file is a cassette-tape image for MSX home computers, the 1983 Japanese
8-bit standard backed by ASCII Corporation and Microsoft. It is the format used
by the fMSX emulator and is the most common way MSX tape software is archived.
Rather than storing raw audio, a CAS file stores the logical tape blocks: each
block is introduced by a fixed sync header, and the emulator regenerates the
frequency-shift-keyed (FSK) audio waveform on playback.

This is a tape image with no filesystem to mount — it is catalogued here for
identification and cross-reference (no driver). Note this is distinct from the
DMK disk format also used on MSX (see related).

## Structure

A CAS file is a sequence of blocks, each beginning with the 8-byte sync header
that lets the decoder lock onto the FSK data. After the header come the block's
bytes; the first ten bytes following a header identify the content type (for
example 0xD0 ten times marks a binary file, 0xD3 a tokenised BASIC file, 0xEA an
ASCII file), followed by a six-character filename and then the payload. MAME
renders this to audio at 22,050 Hz, encoding each byte with a start bit and stop
bit and bit periods that vary with the bit value. The `.tap` extension is also
accepted by some tooling for the same content.

## Detection

Two independent sources — the MAME loader and MSX community documentation — agree
that each CAS block begins with the 8-byte sync sequence
`1F A6 DE BA CC 13 7D 74`. A file therefore typically starts with these bytes,
and the sequence recurs before every subsequent block.

## References

- MAME source: `src/lib/formats/fmsx_cas.cpp`, which matches the 8-byte header
  `{ 0x1F, 0xA6, 0xDE, 0xBA, 0xCC, 0x13, 0x7D, 0x74 }` and FSK-encodes the blocks.
- [How does the .CAS format work? — MSX Resource Center](https://www.msx.org/forum/semi-msx-talk/emulation/how-do-exactly-works-cas-format)
- [Emulation related file formats — MSX Wiki](https://www.msx.org/wiki/Emulation_related_file_formats)
- [Cassette tape — MSX Info Pages (Hans Otten)](https://hansotten.file-hunter.com/technical-info/cassette-tape/)
