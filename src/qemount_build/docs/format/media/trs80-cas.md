---
title: TRS-80 cassette image
created: 1980s
system: TRS-80 (Tandy/Radio Shack Models I, III, 4)
extensions: [".cas"]
aliases:
  - trs_cas
  - TRS-80 CAS
related:
  - format/disk/trs80
  - format/disk/dmk
  - format/media/coco-cas
---

# TRS-80 cassette image

A `.cas` cassette image holds the bitstream of a TRS-80 program tape, byte for
byte as the machine's cassette routine reads it. It is a flat capture of decoded
bits rather than a mountable filesystem, so it is catalogued here for
identification and cross-reference only — there is no on-tape directory to mount
(no driver).

MAME's loader regenerates a playable audio waveform from the bit data and
covers the three TRS-80 tape speeds:

| Variant | Speed | Sample rate (MAME) |
|---------|-------|--------------------|
| Model I Level I | 250 baud | 22 050 Hz |
| Model I Level II | 500 baud | 44 100 Hz |
| Model III / 4 | 1500 baud | 44 100 Hz |

## Structure

There is no container header; the bytes are the tape's own leader and data
stream. The leader and sync marker distinguish the two encodings:

- **Low speed (Level I/II):** a run of zero bytes followed by a single `0xA5`
  sync byte, then the data. Each bit is a clock pulse plus a data pulse (FM-style
  encoding).
- **High speed (Model III/4):** roughly 256 bytes of `0x55` followed by a single
  `0x7F` sync byte, then the data, with each bit encoded as one sine cycle (a
  shorter cycle for a 1 bit, a longer one for a 0). A short silence marks
  end-of-file.

## Detection

Two independent sources agree on the sync markers: a low-speed tape opens with
zero padding terminated by `0xA5`, while a high-speed (Model III/4) tape opens
with a long run of `0x55` terminated by `0x7F`. Because the `.cas` byte stream
starts with the variable-length leader rather than a fixed-offset magic, these
serve as identification heuristics rather than a single anchored signature.

## References

- MAME loader:
  [`src/lib/formats/trs_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/trs_cas.cpp)
  (250/500/1500 baud; low-speed leader of zeros + `0xA5`; high-speed ~256x
  `0x55` + `0x7F`; trailing silence as EOF).
- [TRS-80 tape and file formats — Ira Goldklang's TRS-80 archive](https://www.trs-80.com/sub-tips-file-formats.htm)
  (leader of zero bytes then `0xA5`; 500 vs 1500 baud encodings).
- [trs80-cassette — Lawrence Kesteloot](https://github.com/lkesteloot/trs80/tree/master/packages/trs80-cassette)
  (low- and high-speed `.cas` bit encodings and sync bytes).
