---
title: Aquarius CAQ cassette
created: unknown
system: Mattel Aquarius
extensions: [".caq"]
aliases:
  - Aquarius cassette dump
related:
  - format/media/supercharger
---

# Aquarius CAQ cassette

CAQ is the cassette-tape image format for the Mattel Aquarius, an 8-bit Z80 home
computer Mattel released in 1983. A CAQ file is a byte-for-byte dump of the data
stream a program produces when SAVEd to tape — it is not a disk image,
filesystem, partition table, or archive, so there is nothing to mount. It is
catalogued here as a knowledge-only entry for identification and
cross-reference.

The Aquarius tape interface is a simple FSK scheme: a logical 1 ("mark") is a
1800 Hz tone and a logical 0 ("space") is a 900 Hz tone. Because the two tones
have different durations the bit rate is not constant (roughly 250–300 bit/s in
practice). Each byte is framed serially as one start bit, eight data bits
(MSB first) and two stop bits, with no checksum or parity — the machine does no
tape error checking at all. MAME's loader turns the stored bytes back into this
modulated waveform, bracketed by short runs of silence.

## References

- MAME loader: [`src/lib/formats/aquarius_caq.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/aquarius_caq.cpp)
- [Mattel Aquarius — Wikipedia](https://en.wikipedia.org/wiki/Mattel_Aquarius)
- [Mattel Aquarius FAQ — cassette format](https://archive.kontek.net/aqemu.classicgaming.gamespy.com/aqfaq2.htm)
