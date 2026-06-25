---
title: Philips P2000T cassette (CAS)
created: 1980
system: Philips P2000T (Dutch Z80 home computer)
extensions: [".cas"]
aliases:
  - P2000T CAS
  - p2000t_cas
---

# Philips P2000T cassette (CAS)

The Philips P2000T was a Z80-based home computer sold mainly in the Netherlands
and Germany from 1980. Unusually, it stored data on Philips **Mini Digital
Cassette** (MDCR) tapes — a small block-structured digital cassette rather than
the analogue audio cassettes most home computers used. The `.cas` format is the
emulator representation of such a tape, preserving its fixed-size blocks and
per-block metadata.

This is a **knowledge-only** entry: the tape holds program/data blocks with
headers, but there is no general filesystem to mount, so it is catalogued for
identification and cross-reference and marked no-driver.

## Structure

A tape is a sequence of fixed blocks between a begin-of-tape and end-of-tape
gap. In MAME's representation each block is 1280 bytes: a 1024-byte data record
preceded by control/header area. A short block mark introduces each record —
MAME uses the byte pattern `0xAA 0x00 0x00 0xAA` — and a 32-byte header sits
within the leading area describing the record. The header fields include:

- the RAM transfer/load address (16-bit);
- the total file length across all of the file's blocks (16-bit);
- the number of valid data bytes in this record (16-bit);
- an 8-character filename and a 3-character extension;
- a file-type code (BASIC, program, viewdata, word-processing, or other);
- a data/language code (e.g. German, Swedish, Dutch/English);
- program start and load addresses (16-bit each);
- the record (block) number.

Independent P2000T preservation documentation corroborates the 1024-byte data
record plus 32-byte header arrangement (1056 useful bytes per block, up to 42
blocks per tape). The `0xAA 0x00 0x00 0xAA` block mark and the exact header
field order come from MAME's loader, reverse-engineered from the P2000 monitor
ROM; no independent second source was found that agrees on those bytes, so they
are not promoted to a detection rule here.

## References

- MAME loader: [`src/lib/formats/p2000t_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/p2000t_cas.cpp)
- [The Philips P2000T home computer — Retro Space](https://retrospace.nl/Philips_P2000T_homecomputer.html)
- [Philips P2000 — Wikipedia](https://en.wikipedia.org/wiki/Philips_P2000)
- [M2000 — Philips P2000 emulator (GitHub)](https://github.com/p2000t/M2000)
