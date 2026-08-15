---
title: Sharp X1 tape image (TAP)
created: unknown
system: Sharp X1 (Japanese Z80 home computer)
extensions: [".tap"]
aliases:
  - X1 TAP
  - X1 tape image
related:
  - format/disk/d88
  - format/media/tzx
---

# Sharp X1 tape image (TAP)

This is the cassette-tape image format for the **Sharp X1**, a Z80-based
Japanese home computer line introduced in 1982. Many X1 titles were distributed
on audio cassette, and the `.tap` image preserves that recording as a bit
stream the emulator can replay into the tape input.

MAME handles two variants. The **new** format begins with a 4-byte `TAPE`
identifier, followed by a 17-byte null-terminated title, a few reserved bytes, a
write-protect flag, a recording-format byte, a 4-byte sampling rate (Hz per
bit), a 4-byte tape-data length in bits, a 4-byte tape position, and then the
tape data itself at offset 0x28 (length-in-bits ÷ 8 bytes). The **old** ("X1EMU")
format has no `TAPE` magic — it starts directly with a 4-byte sampling rate and
the raw sample data — and is distinguished precisely because it lacks the
identifier.

This is a structured tape image (header plus bit-level sample data), not a
mountable filesystem — catalogue for identification only; there is no driver.

## Detection

The new-style X1 TAP image begins with the four ASCII bytes `TAPE`
(`0x54 0x41 0x50 0x45`) at offset 0. MAME's loader and independent X1 emulator
documentation agree that this identifier marks the new format and distinguishes
it from the older headerless X1EMU images.

## References

- MAME loader: [`src/lib/formats/x1_tap.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/x1_tap.cpp)
- [Sharp X1 specifications — engineers@work](https://eaw.app/sharpx1-specifications/)
- [Sharp X1 notes — engineers@work](https://eaw.app/sharpx1-notes/)
