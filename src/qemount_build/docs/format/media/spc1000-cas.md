---
title: SPC-1000 cassette image
created: 1983
system: Samsung SPC-1000
extensions: [".tap", ".cas", ".sta", ".ipl"]
aliases:
  - Samsung SPC-1000 tape image
---

# SPC-1000 cassette image

Cassette tape images for the Samsung SPC-1000, an 8-bit home computer released
in Korea in 1983. The SPC-1000 was Samsung's first personal computer: a Zilog
Z80 machine (4 MHz) with a Motorola MC6847 video display generator and a HuBASIC
interpreter in ROM, co-developed with Hudson Soft. Most software shipped on
audio cassette, so emulators rely on tape image files rather than disk images.

This is a knowledge/identification entry only. The payload is an audio-domain
tape stream rather than a mountable filesystem, so there is no driver.

## Structure

MAME's loader handles several related tape representations for the machine:

- **TAP** — a one-byte-per-bit stream of `0x30`/`0x31` characters (ASCII `0`
  and `1`), including the leader and header bits, that the loader turns directly
  into a modulated waveform.
- **CAS** — a 16-byte ASCII identifier (`SPC-1000.CASfmt`) followed by the
  cassette bitstream packed eight bits to a byte, most-significant bit first.
  The leading 16 bytes are skipped when the tape is rendered.
- **STA** — a save-state style image.
- **IPL** — a RAM-dump quickload image.

On replay the bits are converted to a 16-bit PCM waveform: a `1` bit is encoded
as nine low samples followed by nine high samples, and a `0` bit as four low and
four high, around a nominal 17 kHz carrier.

## References

- MAME loader: [`src/lib/formats/spc1000_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/spc1000_cas.cpp)
- [SPC-1000 — Wikipedia](https://en.wikipedia.org/wiki/SPC-1000)
- [SPC-1000 — old-computers.com museum](https://www.old-computers.com/museum/computer.asp?st=1&c=803)
