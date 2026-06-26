---
title: Atari DOS 2 filesystem
created: 1980
system: Atari 8-bit (400/800/XL/XE)
extensions: []
aliases:
  - Atari DOS 2.0S
  - Atari DOS 2.5
  - Atari FMS
related:
  - format/disk/atr
  - format/disk/raw
detect:
  any:
    # No offset-0 magic. Anchor on the VTOC at sector 360 (offset 45952 in the
    # raw sector image): byte 0 is the DOS code (0x02 for DOS 2), bytes 1-2 are
    # the total-sector count, which is a fixed format constant per density.
    - all:
        # DOS 2.0S single density: 707 sectors.
        - offset: 45952
          type: byte
          value: 0x02
        - offset: 45953
          type: le16
          value: 707
    - all:
        # DOS 2.5 enhanced density: 1010 sectors.
        - offset: 45952
          type: byte
          value: 0x02
        - offset: 45953
          type: le16
          value: 1010
---

# Atari DOS 2 filesystem

The on-disk filesystem written by Atari DOS 2.0S and DOS 2.5, the dominant disk
operating systems for the Atari 8-bit line (400/800 and the later XL/XE), via
the FMS (File Management Subsystem). It is a flat, single-directory filesystem
(no subdirectories) on 128-byte-sector floppies — single density (720 sectors)
or enhanced density (1040 sectors, with a second VTOC at sector 1024).

## Structure

- **Boot sectors 1-3** hold the boot record (and DOS.SYS on a bootable disk).
- **VTOC (sector 360)** is the Volume Table of Contents: byte 0 is the DOS code
  (`0x02`), bytes 1-2 the total sector count (707 for DOS 2.0S, 1010 for DOS
  2.5), bytes 3-4 the current free count, and bytes 10-99 a 1-bit-per-sector
  allocation bitmap (1 = free).
- **Directory (sectors 361-368)** holds up to 64 sixteen-byte entries: a status
  flag (`0x42` for a normal in-use file), the sector count, the starting sector,
  and an 8.3 name.
- **File data** is a singly-linked chain of sectors. Each 128-byte sector
  carries 125 data bytes plus a 3-byte footer: a 6-bit file number (a
  consistency tag equal to the directory slot), a 10-bit forward pointer to the
  next sector (0 = last), and the byte count used in the sector.

## Detection

There is no signature byte at offset 0; an Atari DOS volume is identified
structurally by its VTOC. The robust anchor is the DOS code `0x02` at sector
360 (offset 45952) together with the density-specific total-sector constant
(707 or 1010), both at fixed deep offsets. DOS 2.5's high sectors (720-1023)
are tracked by a second VTOC at sector 1024.

## References

- De Re Atari, chapter 9 (the File Management Subsystem)
- [Atari DOS — Wikipedia](https://en.wikipedia.org/wiki/Atari_DOS)
- [jhallen/atari-tools](https://github.com/jhallen/atari-tools) — a working
  Atari DOS 2 reader/writer used to validate the `mkataridos` generator.
