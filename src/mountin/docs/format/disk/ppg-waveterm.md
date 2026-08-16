---
title: PPG Waveterm Disk Image
created: 1982
system: PPG Waveterm (Wave synthesizer system)
extensions: [".wta", ".dsk"]
aliases: [PPG Waveterm, Waveterm A, WTA, ppg_dsk]
related:
  - format/disk/flex
  - format/disk/esq8
  - format/disk/fz1
---

This is a floppy image for the PPG Waveterm, the disk-based wavetable/sampling
terminal made by Palm Products GmbH (PPG) of Germany to accompany the PPG Wave
synthesizers in the early 1980s. The Waveterm was effectively a small computer
(a Eurocom II board running a Flex9-derived OS) with its own floppy drives, used
to store and edit waveforms, wavetables and samples. MAME's loader covers both
the native Waveterm disks and FLEX-style images produced by the `flexemu`
emulator.

## Structure

The format is MFM, 256-byte sectors, handled through MAME's `wd177x_format` base
class with several fixed geometries:

- 5.25" SS/DD, 10 sectors/track, 35 or 40 tracks
- 5.25" DS/DD, 10 sectors/track, 35 or 40 tracks (2 heads)
- 5.25" DS/DD, 20 sectors/track, 35 or 40 tracks (2 heads)
- 5.25" DS/DD, 16 sectors/track, 77 tracks (2 heads) — the `.wta` ("Waveterm A"
  transfer) variant

The first six (10/20-sector) layouts are the flexemu `.dsk` set; the 16-sector,
77-track layout is the `.wta` form. Gap parameters (32, 22, 31 for the standard
sets and 32, 2, 2 for the higher-density ones) are noted as unverified in the
source. There is no header magic — geometry alone distinguishes the variants.

## References

- MAME source: `src/lib/formats/ppg_dsk.cpp`
  (https://github.com/mamedev/mame/blob/master/src/lib/formats/ppg_dsk.cpp)
- Palm Products GmbH, Wikipedia:
  https://en.wikipedia.org/wiki/Palm_Products_GmbH
- The Floppy Interface in Waveterm A and B, hermannseib.com:
  https://www.hermannseib.com/english/synths/ppg/wtfloppy.htm
- PPG Waveterm, ppg.synth.net:
  https://ppg.synth.net/waveterm/
