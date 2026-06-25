---
title: Thomson cassette image (.k7 / .k5)
created: 1982
system: Thomson TO7, TO7/70, MO5, MO6 (French 8-bit)
extensions: [".k7", ".k5", ".wav"]
aliases: ["Thomson K7", "TO7 cassette", "MO5 cassette"]
related:
  - format/disk/thom
  - format/disk/sap
---

# Thomson cassette image (.k7 / .k5)

A cassette-tape image for the Thomson family of French 8-bit home computers
(TO7 1982, TO7/70, MO5 1984, MO6). These machines loaded software from audio
cassette, and an image preserves either the raw audio waveform or a demodulated
byte stream of the tape's logical blocks. It is catalogued here for
identification and cross-reference; it is a sequential program/data tape, not a
mountable filesystem, so there is no driver.

Two encodings exist and are mutually incompatible despite both being Thomson:

- **TO7** tapes (commonly `.k7`) use a frequency-modulated bit cell — roughly
  seven cycles at 6300 Hz for a `1` bit and five cycles at 4500 Hz for a `0`.
  Logical blocks open with a two-byte `01 3C` header, then a block type byte
  (file-header, data, or end), a length byte, the data, and a checksum, with
  runs of `0xFF` filler between blocks.
- **MO5 / MO6** tapes (commonly `.k5`, though `.k7` is also seen, which is
  confusing) use a simpler MFM-style scheme decoded entirely in software.
  Blocks open with a `3C 5A` header followed by type, length, data and a
  checksum, separated by `0x01` filler bytes.

An image may instead be a plain `.wav` of the analogue signal; MAME accepts both
the `.k7`/`.k5` byte-stream form and `.wav`, converting the byte stream back into
a synthesised waveform for the emulated cassette deck. For preservation the raw
`.wav` is generally regarded as the more robust container, especially for MO5
where copy-protected loaders deliberately deviate from the plain byte stream.

The `.k7`/`.k5` extensions overlap by convention and do not by themselves tell
you which machine a tape targets; the header bytes (`01 3C` vs `3C 5A`) are the
reliable discriminator.

## References

- MAME source: `src/lib/formats/thom_cas.cpp` and `thom_cas.h` — defines
  `to7_cassette_formats` and `mo5_cassette_formats`; documents the `01 3C` /
  `3C 5A` block headers, filler bytes and the TO7 6300/4500 Hz bit timing.
- A. Miné, "Thomson MO5 / TO7 Emulation in MESS" (lip6.fr) — corroborates the
  TO7-vs-MO5 encoding incompatibility, the MFM-in-software MO5 scheme, and the
  `.wav` / `.k5` / `.k7` container conventions.
- DCMOTO / k72wav project documentation — `.k7`↔`.wav` conversion for TO7/MO5.
