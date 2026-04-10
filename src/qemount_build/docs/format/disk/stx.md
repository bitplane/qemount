---
title: STX (Pasti)
created: 2001
related:
  - format/disk/msa
  - format/disk/raw
  - format/fs/gemdos
detect:
  - offset: 0
    type: string
    value: "RSY\x00"
---

# STX (Pasti)

STX is the Pasti disk image format created by Jean-Louis Guerin
(DrCoolZic) around 2001. It preserves copy-protected Atari ST floppy
disks at a level beyond what raw sector dumps can capture, recording
timing data, weak sectors, and fuzzy bits that copy protection schemes
relied upon.

## Characteristics

- Per-track timing and fuzzy bit data
- Weak/variable sector support
- Multiple sector size support
- Preserves copy protection schemes
- Used by Hatari and other Atari ST emulators
- More detailed than MSA but less common

## Structure

```
Header:
  Offset  Size  Field
  0       4     Magic ("RSY\x00")
  4       2     Version
  6       2     Tool (creator ID)
  8       2     Reserved
  10      1     Track count
  11      1     Revision
  12      4     Reserved
```

Followed by per-track descriptors and sector data.

## File Extension

`.stx`

## References

- [Pasti project](http://pasti.fandal.cz/)
- Companion to MSA for Atari ST disk preservation
