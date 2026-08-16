---
title: Lviv LVT (cassette image)
created: unknown
system: PK-01 Lviv (Soviet / Ukrainian SSR, 1986)
extensions: [".lvt", ".lvr", ".lv0", ".lv1", ".lv2", ".lv3"]
aliases:
  - PK-01 Lviv tape
  - PC-01 Lviv tape
  - LVOV tape
related:
  - format/disk/bk0010
  - format/disk/agat840k
---

# Lviv LVT (cassette image)

A structured cassette image for the PK-01 "Lviv", an 8-bit Soviet home computer
designed in Lviv (Ukrainian SSR) and produced from around 1986. The `.lvt` file
is not raw audio: it is a byte stream that an emulator (or MAME) modulates into a
tape waveform on load, replaying the machine's cassette protocol.

This is a **knowledge-only** entry — a tape program image, not a mountable
filesystem, so it carries no driver.

## Structure

MAME's loader treats the file as a leader/header/data sequence rather than
checking a file signature:

- A **pilot tone** (a long run of alternating pulses) for synchronisation.
- A short **header** built from the leading bytes of the file — MAME emits the
  byte at offset `0x09` ten times, followed by six header bytes at offsets
  `0x0a`–`0x0f`. Each byte is framed with a start bit and two stop bits.
- A silent **pause**, a second shorter pilot tone, then the remaining bytes as
  the **data block**.

Bit cells are encoded as pulse runs (a `1` and a `0` use different pulse counts),
and the loader renders the whole thing at 44.1 kHz. There is no validated magic
number, so the format is identified by extension/context rather than a header
signature. Multipart tapes use the numbered `.lv0`…`.lv3` extensions, with the
`.lvt` part loaded first; `.lvr` is a related Lviv tape variant.

## References

- MAME loader: [`src/lib/formats/lviv_lvt.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/lviv_lvt.cpp)
- [PK-01 Lviv — emulator/system notes (progettoemma / MESS)](http://www.progettoemma.net/mess/system.php?machine=lviv)
- [Lviv PK-01 collection notes (spookbench)](https://spookbench.net/collection/lviv/index.html)
