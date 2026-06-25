---
title: Sanyo PHC-25 Cassette Image
created: 1982
system: Sanyo PHC-25
extensions: [".phc"]
aliases: [PHC-25 tape, phc25_cas]
related:
  - format/media/fm7-cas
  - format/media/mz-cas
---

The `.phc` file is a cassette-tape image for the Sanyo PHC-25, a Z80A-based
Japanese home computer announced in mid-1982 and sold abroad through 1983. The
PHC-25 was the top model of Sanyo's short-lived PHC line and shipped with Sanyo
BASIC v1.3; programs were saved to and loaded from audio cassette. A `.phc`
image is the byte-level capture of such a tape's payload, from which an emulator
synthesises the loading waveform.

This is a tape image with no filesystem to mount — it is catalogued here for
identification and cross-reference (no driver).

## Structure

MAME's loader treats the file as a tokenised BASIC tape image. It expects a
leading run of ten `0xA5` bytes acting as a header marker, followed by six bytes
holding the program name, then the BASIC program body (lines terminated by null
bytes, the program ending at three consecutive nulls) and the line-number /
pointer table that runs to the end of the image. A final `0xFF` trailer byte is
present but not emitted. When rendering audio, each byte becomes one start bit
(0), eight data bits LSB-first and four stop bits (1), with bit cells expressed
as alternating sample levels; MAME drives this at a 9600-sample reference rate
and pads the stream with the usual silence, a high-bit sync run and a header
section that a real PHC-25 tape would carry.

(The `0xA5`-run header and the bit framing are described from the MAME loader
only; independent sources confirm the PHC-25's existence and its cassette-based
storage but were not cross-checked at the byte level, so no formal detection rule
is asserted here.)

## References

- MAME source: `src/lib/formats/phc25_cas.cpp`
  (https://github.com/mamedev/mame/blob/master/src/lib/formats/phc25_cas.cpp)
- Sanyo PHC-25, Wikipedia:
  https://en.wikipedia.org/wiki/Sanyo_PHC-25
- PHC-25 (Sanyo), old-computers.com museum:
  https://www.old-computers.com/museum/computer.asp?st=1&c=192
