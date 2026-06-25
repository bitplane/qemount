---
title: Coleco Adam Digital Data Pack (DDP)
created: 1983
system: Coleco Adam
extensions: [".ddp"]
aliases:
  - Adam tape
  - Digital Data Pack
related:
  - format/disk/adam
---

# Coleco Adam Digital Data Pack (DDP)

The Digital Data Pack was the high-speed cassette medium of the Coleco Adam
(1983). Unlike an ordinary audio tape it stores phase-encoded digital data with
a directory and per-block checksums, which the Adam's Elementary Operating
System (EOS) addresses as a sequence of 1 KB blocks — the same block model used
by the Adam's [floppy disks](../disk/adam).

This is a **knowledge-only** entry — a structured tape image, not a mountable
filesystem.

## Structure

The image is organised into 1 KB blocks with a central directory. Each control
record carries (per MAME's loader):

- 2-byte header id — `HE` (`0x48 0x45`, central-directory type) or `GW`
  (`0x47 0x57`)
- 2-byte block number, then its bitwise complement
- 1-byte block count (`0x80`)
- 1-byte checksum of the preceding header bytes

Data blocks carry a 16-bit checksum, and the tape stream is framed with sync
bytes (`0x16`, `0xAA`).

## References

- MAME loader: [`src/lib/formats/adam_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/adam_cas.cpp)
- [Coleco Adam — Wikipedia](https://en.wikipedia.org/wiki/Coleco_Adam)
