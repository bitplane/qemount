---
title: Microbee TAP (cassette image)
created: unknown
system: Microbee (Applied Technology / Microbee Systems, Australia, 1982, Z80)
extensions: [".tap"]
aliases:
  - mbee tape
  - Microbee cassette
related:
  - format/disk/excali64
---

# Microbee TAP (cassette image)

A structured cassette image for the Microbee, the Australian Z80 home computer
first sold (as a kit) by Applied Technology in 1982. The `.tap` file is not raw
audio: it is a byte stream that an emulator (or MAME) modulates into the tape
waveform, replaying the Microbee's variant of the Processor Technology
SOLOS/CUTER (CUTS) cassette protocol at 300 or 1200 baud.

This is a **knowledge-only** entry — a tape program image, not a mountable
filesystem, so it carries no driver.

## Structure

The file opens with a null-terminated ID string (MAME accepts values such as
`TAP_DGOS_BEE`), then one or more file entries. Each entry is:

- a **leader** of 63 zero bytes,
- an **18-byte header**, and
- the **data** payload in CRC-checked chunks.

The header carries the metadata SOLOS/CUTER expects:

| Offset | Size | Field |
|--------|------|-------|
| 0x00 | 1 | SOH marker (`0x01`) |
| 0x01 | 6 | Filename (6 chars) |
| 0x07 | 1 | File type (`M` = machine code, `B` = BASIC) |
| 0x08 | 2 | Length (little-endian) |
| 0x0a | 2 | Load address |
| 0x0c | 2 | Execution address |
| 0x0f | 1 | Speed (0 = 300 baud, non-zero = 1200 baud) |
| 0x10 | 1 | Auto-start flag |
| 0x11 | 1 | Header CRC |

On modulation each byte becomes a start bit (0), 8 data bits LSB-first, and two
stop bits (1); a `1` and a `0` use different pulse-sample counts, doubled at the
300-baud rate. The header field set (6-char name, M/B type, load/exec address,
300/1200 baud, autostart) is corroborated by Microbee tape tooling such as
`bin2tap` / `tapetool`.

## References

- MAME loader: [`src/lib/formats/mbee_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/mbee_cas.cpp)
- [MicroBee — Wikipedia](https://en.wikipedia.org/wiki/MicroBee)
- [bin2tap — Microbee binary-to-tape converter (toptensoftware)](https://github.com/toptensoftware/bin2tap)
- [TapeTool2 — Microbee/TRS-80 tape tooling (Topten Software)](https://www.toptensoftware.com/tapetool/)
