---
title: Canon X-07 cassette image
created: 1983
system: Canon X-07 (Japanese handheld computer)
extensions: [".k7", ".cas", ".lst"]
aliases:
  - X-07 cassette
  - X07 K7
related:
  - format/media/tzx
---

# Canon X-07 cassette image

This is a cassette image for the **Canon X-07**, a Japanese handheld/pocket
computer released in 1983. The X-07 was built around an NSC800 CPU (a
Z80-compatible part) and shipped with Microsoft BASIC; a cassette interface let
it save and load programs and data to ordinary audio tape.

The image stores the logical byte stream that the X-07's tape routines record,
which MAME's loader turns back into an audio waveform for the emulated cassette
input. The encoding is a frequency/pulse scheme: bits are framed as one start
bit (0), eight data bits sent least-significant-first, and three stop bits (1).
A program is preceded by a leader of high bits and, for a named/typed file, a
short header block of identification bytes; MAME keys on a run of `0xD3` bytes
to recognise a valid header, after which the body follows a short pause.

This is a tape image with framing and an optional header, not a mountable
filesystem — catalogue for identification only; there is no driver. The `.k7`
extension (from French *cassette*, "K-sept") is common to several emulated
cassette formats; `.lst` and `.cas` are also accepted by MAME's loader.

## References

- MAME loader: [`src/lib/formats/x07_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/x07_cas.cpp)
- [Canon X-07 — Wikipedia](https://en.wikipedia.org/wiki/Canon_X-07)
- [Canon X-07 — Old Machinery](http://oldmachinery.blogspot.com/2013/09/canon-x-07.html)
