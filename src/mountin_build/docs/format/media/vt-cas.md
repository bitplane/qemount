---
title: VTech VZ / Laser cassette image
created: 1983
system: VTech Laser 110/200/210/310, Dick Smith VZ-200/VZ-300
extensions: [".cas"]
aliases:
  - VZ-200 cassette
  - VZ cassette
  - Laser 200 tape
  - vtech1 cas
  - vtech2 cas
related:
  - format/fs/vtech
  - format/disk/vtech-disk
---

# VTech VZ / Laser cassette image

A byte-level capture of the cassette-tape program format used by VTech's Laser
110/200/210/310 home computers and their rebadged Australasian twins, the Dick
Smith VZ-200 and VZ-300 (from 1983). A `.cas` file is not sampled audio; it is
the logical byte stream the machine's ROM writes to and reads from tape, from
which an emulator synthesises the modulated audio waveform.

This is a tape program-load image, not a mountable filesystem, so it is
catalogued here for identification and cross-reference only — there is no
on-tape directory to mount.

## Structure

MAME's loader supports two speed variants, reflecting the two generations of
hardware:

- **VTech 1** — the slower scheme used by the Laser 110/200/210 and VZ-200.
- **VTech 2** — the faster scheme used by the Laser 310 and VZ-300.

A recorded file begins with a run of silence/leader, followed by the program
header — a file-type byte, a short filename, and the load (start) and end
addresses — and then the program body, mirroring the same filename and
load/end-address fields the disk filesystem stores in its directory entries.
The two variants differ in bit timing: independent analysis of the Laser/VZ tape
encoding describes a "one" bit as a short train of ~1660 Hz cycles and a "zero"
as a single ~1660 Hz cycle followed by an ~830 Hz half-cycle, giving a bit rate
on the order of ~550 bits per second for the original machines; the VTech 2
scheme runs proportionally faster. Because the `.cas` container stores the raw
data bytes rather than the audio, the file carries no fixed image-level magic
number, and no detection rule is given here.

## References

- MAME source: [`src/lib/formats/vt_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/vt_cas.cpp)
- [VTech Laser 200 — Wikipedia](https://en.wikipedia.org/wiki/VTech_Laser_200)
- [The VZ200 — KernelCrash](https://www.kernelcrash.com/blog/the-vz200/2023/01/18/)
- [z88dk — VZ200 platform / appmake `+vz` CAS support](https://www.z88dk.org/wiki/doku.php?id=platform:vz200)
- [The Dick Smith VZ-200 / VZ-300 computer — vz200.org](http://www.vz200.org/bushy/history.htm)
