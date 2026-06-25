---
title: Camputers Lynx cassette (TAP)
created: unknown
system: Camputers Lynx (UK, 1983)
extensions: [".tap"]
aliases:
  - Lynx TAP
  - PALE/Jynx tape
related:
  - format/disk/camplynx
---

# Camputers Lynx cassette (TAP)

A tape image for the Camputers Lynx, a British Z80 home computer launched in
1983 in 48K and 96K (later 128K) models. Camputers folded after about 18 months
having sold roughly 30,000 machines. The `.tap` convention is shared by the two
main Lynx emulators, Pete Todd's PALE and Jonathan Markland's Jynx, and stores
the bit stream a Lynx tape program loads from.

This is a **knowledge-only** entry. It is a serial program-load encoding, not a
disk image, filesystem, partition table, or archive — there is nothing to mount.
It is catalogued for identification and cross-reference.

## Structure

MAME's loader reconstructs the cassette waveform from a structured byte stream:

- A long run of zero bytes (a leader/silence, on the order of several seconds)
- A `0xA5` synchronisation byte
- An optional program name, delimited by `0x22` (`"`) on each side
- A file-type indicator byte: `A`, `B`, or `M`
- A second sync sequence (zero leader plus `0xA5`)
- A data block whose length is taken from a 16-bit length field inside a small
  per-type header (type `A`, `B`, and `M` carry different fixed header layouts)
- Trailing checksum bytes

Type `B` denotes a Lynx BASIC program; `A` and `M` cover the other load types.
Each byte is shifted out MSB-first, and bits are modulated to different sample
counts, with the base frequency differing between the 48K (4 kHz) and 128K
(8 kHz) machines.

## References

- MAME loader: [`src/lib/formats/camplynx_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/camplynx_cas.cpp)
- [Jynx — Camputers Lynx emulator (GitHub)](https://github.com/jonathan-markland/Jynx)
- [Looking into the TAP files — Jynx blog](https://jynx-emulator.tumblr.com/post/96117326757/looking-into-the-tap-files)
- [PALE Lynx Emulator](http://www.russelldavis.org/CamputersLynx/PALE/)
- [Camputers Lynx — RetroBat Wiki](https://wiki.retrobat.org/systems-and-emulators/supported-game-systems/home-computer/camputers-lynx)
