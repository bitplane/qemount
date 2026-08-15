---
title: Heathkit H8 cassette (H8T)
created: 1977
system: Heathkit H8 / H-88 (Z80/8080 microcomputer)
extensions: [".h8t"]
aliases:
  - H8 cassette
  - Heath H8 tape
related:
  - format/disk/h17disk
---

# Heathkit H8 cassette (H8T)

An audio-cassette program/data image for the Heathkit H8, the 8080-based kit
microcomputer introduced in 1977 (and its H-88 sibling). Before the H-17 floppy
subsystem, the H8 loaded and saved programs to ordinary audio cassette via its
H-8-5 serial/cassette interface.

This is a **knowledge-only** entry: it is a serial bitstream modulated onto
audio, not a mountable filesystem, disk image, partition table or archive. There
is nothing to mount, so it is catalogued for identification and cross-reference
and carries no driver.

## Encoding

The tape uses the **Kansas City Standard**-style FSK scheme at 300 baud, the
common interchange rate for late-1970s microcomputers. Bits are represented by
bursts of two audio tones (MAME's loader labels them ~1200 Hz and ~2400 Hz),
sinewave-modulated. The stream is framed asynchronously like a serial line:

- A leader of about one second of steady marking bits for the receiver to lock on
- The data payload (the file contents)
- Each data byte sent as a start bit (0), 8 data bits, and a stop bit (1)

There is no in-band magic signature; the format is recognised by its `.h8t`
extension and its audio framing rather than by a header.

## References

- MAME loader: [`src/lib/formats/h8_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/h8_cas.cpp)
- [Heath H8 — Wikipedia](https://en.wikipedia.org/wiki/Heathkit_H8)
- [Kansas City standard — Wikipedia](https://en.wikipedia.org/wiki/Kansas_City_standard) (300-baud FSK cassette encoding)
- [Peripherals for Heathkit Computers](https://heathkit.garlanger.com/peripherals/)
