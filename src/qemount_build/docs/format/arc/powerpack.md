---
title: PowerPacker
created: 1989
detect:
  any:
    - offset: 0
      type: string
      value: "PP20"
    - offset: 0
      type: string
      value: "PP11"
---

# PowerPacker

PowerPacker was created by Nico Francois around 1989 for the Amiga. It
was the most widely-used compression tool in the Amiga scene, used for
everything from game data to demo scene productions. Nearly ubiquitous
on the Amiga platform.

## Characteristics

- Fast decompression (designed for 7MHz 68000)
- Multiple compression quality levels
- Single-file compression (not a multi-file archive)
- Used as both a standalone tool and embedded in Amiga software

## Detection

| Magic | Version |
|-------|---------|
| `PP11` | PowerPacker 1.1 |
| `PP20` | PowerPacker 2.0 (most common) |

PP20 quality is encoded at offset 4:

| Bytes at offset 4 | Quality |
|-------------------|---------|
| `09 09 09 09` | Fast |
| `09 0A 0A 0A` | Mediocre |
| `09 0A 0B 0B` | Good |
| `09 0A 0C 0C` | Very good |
| `09 0A 0C 0D` | Best |

## File Extension

`.pp` (conventionally)
