---
title: FM-7 T77 Cassette Image
created: unknown
system: Fujitsu FM-7
extensions: [".t77"]
aliases: [T77, XM7 tape image, fm7_cas]
related:
  - format/disk/d88
---

The T77 file is a cassette-tape image for the Fujitsu FM-7 series of Japanese
home computers (the FM-7, "Fujitsu Micro 7", launched in 1982, and its
descendants). It captures the magnetic waveform of a program tape at the
signal-level transition layer rather than as raw audio samples, which is why a
T77 file is much smaller than an equivalent WAV recording. The format originates
with the XM7 emulator and is the de-facto interchange format for archived FM-7
tape software; later emulators such as 77AVEMU read it too.

This is a tape image with no filesystem to mount — it is catalogued here for
identification and cross-reference (no driver).

## Structure

MAME's reader validates a fixed 16-byte ASCII header, the string
`XM7 TAPE IMAGE 0`, at the start of the file. The body that follows is a stream
of 16-bit big-endian wave instructions: the top bit selects the output level
(high or low), and the remaining 15 bits give the number of samples to hold that
level. MAME synthesises audio from this at 110,250 Hz. Because the data is a
run-length list of level changes, the file stores the tape's bit timing compactly
without per-sample storage.

(The exact 16-byte signature is described from the MAME loader only; independent
sources confirm the `.t77` "XM7 Tape Image" identity but were not cross-checked
at the byte level, so no formal detection rule is asserted here.)

## References

- MAME source: `src/lib/formats/fm7_cas.cpp`, which checks
  `memcmp(casdata, "XM7 TAPE IMAGE 0", 16)` and decodes the 16-bit big-endian
  wave entries.
- [T77 File — file.org](https://file.org/extension/t77)
- [Fujitsu FM-7 Tape Dumps — Gaming Alexandria](https://www.gamingalexandria.com/wp/2020/12/fujitsu-fm-7-tape-dumps/)
- [77AVEMU — emulator for the Fujitsu FM-7 series (GitHub)](https://github.com/captainys/77AVEMU)
