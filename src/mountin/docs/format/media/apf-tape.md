---
title: APF Imagination Machine cassette (APT/CPF)
created: 1979
system: APF Imagination Machine / APF-MP1000
extensions: [".apt", ".cas", ".cpf"]
aliases:
  - APF cassette
related:
  - format/media/cdda
---

# APF Imagination Machine cassette (APT/CPF)

A structured cassette image for the APF Imagination Machine (and the APF-MP1000
console base), a 1979 US home computer/console from APF Electronics. The file
holds a program as a byte stream that an emulator (or MAME) modulates into the
tape waveform on load.

This is a **knowledge-only** entry — a tape program image, not a mountable
filesystem.

## Structure

The encoder works through identifiable sections rather than treating the file as
opaque (per MAME's loader):

- a leading silence and a preamble of bits
- a `0xFE` marker indicating the start of a program in the APT variant
- screen-RAM and program-RAM regions
- an 8-bit additive checksum

Bytes are emitted most-significant-bit first with no start/stop bits. The CPF
and CAS variants are a fixed `0x1E00` bytes.

## References

- MAME loader: [`src/lib/formats/apf_apt.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/apf_apt.cpp)
- [APF Imagination Machine — Wikipedia](https://en.wikipedia.org/wiki/APF_Imagination_Machine)
