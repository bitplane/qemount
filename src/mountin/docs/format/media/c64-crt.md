---
title: Commodore 64 cartridge (CRT)
created: unknown
system: Commodore 64 / 128
extensions: [".crt"]
aliases:
  - CCS64 cartridge
  - C64 CARTRIDGE
related:
  - format/media/c64-tap
---

# Commodore 64 cartridge (CRT)

A container for Commodore 64/128 cartridge ROM images, originally introduced by
the CCS64 emulator and now the de-facto interchange format for C64 carts. Unlike
a bare ROM dump, the CRT file describes the cartridge hardware — its bank-switch
type and the state of the EXROM/GAME control lines — so an emulator can map the
ROM banks correctly.

This is a **knowledge-only** entry: it is a cartridge ROM container, not a disk
image, filesystem, partition table, or archive. There is nothing to mount; it is
catalogued for identification and cross-reference.

## Structure

A 64-byte file header is followed by one or more `CHIP` packets:

- **Header**
  - `0x00`: 16-byte signature `C64 CARTRIDGE   ` (space-padded)
  - `0x10`: header length (big-endian, normally `0x00000040`)
  - `0x14`: version (e.g. 1.00)
  - `0x16`: hardware/cartridge type (selects the bank-switching scheme)
  - `0x18`: EXROM line state
  - `0x19`: GAME line state
  - `0x1A`: reserved
  - `0x20`: 32-byte cartridge name (null-padded)
- **CHIP packets** (repeat for each ROM block)
  - `+0x00`: signature `CHIP`
  - `+0x04`: total packet length (big-endian, header + ROM data)
  - `+0x08`: chip type (0 = ROM, 1 = RAM, 2 = Flash ROM)
  - `+0x0A`: bank number
  - `+0x0C`: starting load address (e.g. `0x8000`)
  - `+0x0E`: ROM image size
  - `+0x10`: ROM data

MAME maps dozens of hardware-type values to its cartridge slot handlers (Action
Replay, Retro Replay, MMC64, Easyflash and many more), some unsupported.

## Detection

Both MAME's loader and the community CRT specification agree the file opens with
the 16-byte ASCII signature `C64 CARTRIDGE   ` (the name padded with trailing
spaces to 16 bytes), and that each ROM block begins with the 4-byte ASCII
signature `CHIP`.

## References

- MAME loader: [`src/lib/formats/cbm_crt.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/cbm_crt.cpp)
- [CRT Format — ReplayResources wiki](https://rr.pokefinder.org/wiki/CRT_Format)
- [Cartridge — C64-Wiki](https://www.c64-wiki.com/wiki/Cartridge)
