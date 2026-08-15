---
title: TZX (ZX Spectrum tape)
created: 1997
system: ZX Spectrum (also Amstrad CPC, SAM Coupe, MSX variants)
extensions: [".tzx", ".tsx", ".cdt", ".tap", ".blk"]
aliases:
  - Tape eXtended
  - CDT
related:
  - format/media/csw
  - format/disk/trd
  - format/disk/scl
---

# TZX (ZX Spectrum tape)

TZX ("Tape eXtended") is the de-facto standard tape-image format for the ZX
Spectrum, and the most expressive of the Spectrum tape formats. Where the simpler
`.tap` format stores only the bytes of standard ROM-loader blocks, TZX is a
block-structured container designed to reproduce *any* signal a Spectrum could
put on tape — including turbo loaders, custom loading schemes, pure-tone and
pure-data sequences, direct sampled recordings, and embedded text/metadata. The
format was devised in the late 1990s (commonly credited to Tomaz Kac, with
Martijn van der Heide and RAMSoft) to preserve copy-protected and fast-loading
tapes that `.tap` cannot represent.

The same block format is reused for other 8-bit machines: the Amstrad CPC uses it
under the `.cdt` extension, and MSX-oriented variants appear as `.tsx`. MAME's
loader handles `.tzx`, `.tsx`, `.tap`, `.blk` and `.cdt`, scaling block timings
for CPC where appropriate.

This is a **knowledge-only** media entry: it encodes a tape signal as a sequence
of timing/data blocks, not a mountable filesystem. It is catalogued for
identification and cross-reference; no driver is planned. For a sample-level tape
capture see [CSW](csw.md); Spectrum *disk* software instead uses formats such as
[TRD](../disk/trd.md) and [SCL](../disk/scl.md).

## Structure

A TZX file is a 10-byte header followed by a stream of self-describing blocks.
The header is the signature (below), a terminator byte, and a major/minor version
pair; MAME supports major version 0x01. Each block begins with a one-byte block
ID that selects its layout. Commonly used IDs include:

- 0x10 standard speed data block; 0x11 turbo loading data block
- 0x12 pure tone; 0x13 pulse sequence; 0x14 pure data block
- 0x15 direct recording; 0x18 CSW recording; 0x19 generalized data block
- 0x20 pause / stop the tape; 0x24 / 0x25 loop start / end
- 0x30–0x35 text description, message, archive info, hardware info, custom info
- 0x4B TSX data block; 0x5A "glue" block

All timings are expressed against the Spectrum's 3.5 MHz clock, which lets a TZX
file describe exact pulse lengths independent of the playback sample rate.

## Detection

Multiple independent sources agree that a TZX file begins with the seven ASCII
characters `ZXTape!` followed by the terminator byte 0x1A — eight bytes total
(`5A 58 54 61 70 65 21 1A`), then the two version bytes. The MAME loader, the
World of Spectrum TZX specification, and the Just Solve / archive-team format
references all describe this same signature.

## References

- MAME loader: [`src/lib/formats/tzx_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/tzx_cas.cpp)
- [TZX technical specifications — World of Spectrum](https://worldofspectrum.net/TZXformat.html)
- [TZX — Just Solve the File Format Problem](http://fileformats.archiveteam.org/wiki/TZX)
