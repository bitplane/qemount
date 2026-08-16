---
title: SOL-20 Sol Virtual Tape (SVT)
created: 1976
system: Processor Technology SOL-20 (S-100, 8080)
extensions: [".svt"]
aliases:
  - SVT
  - Sol Virtual Tape
  - SOL-20 cassette
related:
  - format/media/microbee-tap
---

# SOL-20 Sol Virtual Tape (SVT)

A cassette image format for the **Processor Technology SOL-20**, the 1976
8080-based S-100 computer that was among the first machines sold as a complete
unit with an integrated keyboard. The SOL-20 stored programs and data on ordinary
audio cassette through its built-in CUTS (Computer Users' Tape System) interface.

This is a **knowledge-only** entry. The payload is a serial bitstream modulated
onto audio, not a mountable filesystem, disk image, partition table or archive,
so it is catalogued for identification and cross-reference and carries no driver.

Unlike a raw audio capture, the `.svt` file is a *structured text* description of
a virtual tape (hence "Sol Virtual Tape"): MAME's loader parses an ASCII script
and synthesises the audio waveform from it.

## Structure

The file begins with the literal text `SVT` and is then a sequence of one-letter
commands. MAME's loader handles:

- **`C`** — carrier (idle) tone, with a duration given in decaseconds
- **`H`** — a file header carrying the program name, type, length, load address
  and execution address
- **`D`** — data bytes given in hexadecimal

A logical tape is laid out as an idle leader tone, a header, then data blocks of
up to 256 bytes each followed by a CRC byte (the final block may be short).
Commands the loader does not implement include `B` (baud-rate select), `S`
(silence) and escaped characters; multiple programs may appear in one file.

## Encoding

The CUTS scheme records the UART bitstream as two audio tones. At the default
1200-baud rate a `1` bit is one full cycle of 1200 Hz and a `0` bit is a half
cycle of 600 Hz; each byte is framed as a start bit, 8 data bits sent
least-significant first, and 2 stop bits. (A 300-baud Kansas City Standard mode
also existed on the hardware but is not handled by this loader.)

MAME's parser keys off the leading `SVT` text to recognise the file, but I have
not found an independent source documenting that exact tag, so no formal
detection rule is asserted here.

## References

- MAME loader: [`src/lib/formats/sol_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/sol_cas.cpp)
- [Sol-20 — Wikipedia](https://en.wikipedia.org/wiki/Sol-20)
- [The SOL-20 Computer's Cassette Interface (worldphaco.com)](https://worldphaco.com/uploads/The_SOL-20_tape.pdf)
- [Solace Virtual Tape Drive (sol20.org)](http://www.sol20.org/solace/solace_tape.html)
