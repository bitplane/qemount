---
title: Exidy Sorcerer cassette image
created: 1978
system: Exidy Sorcerer (Z80, S-100)
extensions: [".tape"]
aliases:
  - Sorcerer cassette
  - Sorcerer tape
related:
  - format/disk/sorcerer
---

# Exidy Sorcerer cassette image

A cassette image for the **Exidy Sorcerer**, the Z80-based home/S-100 computer
launched by arcade maker Exidy in April 1978. The Sorcerer used an external
audio cassette recorder at 1200 baud as its standard mass storage (its other
notable medium being the "ROM PAC" cartridge built into 8-track shells);
floppy disks and CP/M came later via the S-100 expansion chassis.

This is a **knowledge-only** entry. The payload is a serial bitstream modulated
onto audio rather than a mountable filesystem, disk image, partition table or
archive, so it is catalogued for identification and cross-reference and carries
no driver.

## Structure

A logical tape consists of an idle high-tone leader, a header, and then data
blocks of 256 bytes each followed by a CRC byte, with a final, possibly shorter
block. There is no in-band magic signature; the image is recognised by its
`.tape` extension and audio framing rather than a header.

## Encoding

The Sorcerer uses an FSK scheme at 1200 baud: a `1` bit is one full cycle of
1200 Hz and a `0` bit is a half cycle of 600 Hz. Each byte is framed
asynchronously as 1 start bit, 8 data bits, and 2 stop bits. MAME synthesises the
waveform at a 4788 Hz sample rate.

## References

- MAME loader: [`src/lib/formats/sorc_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/sorc_cas.cpp)
- [Exidy Sorcerer — Wikipedia](https://en.wikipedia.org/wiki/Exidy_Sorcerer)
- [Exidy Sorcerer (1978) — Retromobe](https://www.retromobe.com/2018/04/exidy-sorcerer-1978.html)
