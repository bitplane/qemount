---
title: Videoton TVC cassette
created: 1985
system: Videoton TV-Computer (TVC)
extensions: [".cas"]
aliases:
  - TVC CAS
  - TV-Computer cassette
related:
  - format/disk/tvc
---

# Videoton TVC cassette

`.cas` is the cassette-tape image format for the Videoton TV-Computer (TVC), a
Z80-based home computer built by the Hungarian electronics manufacturer Videoton
and sold from the mid-1980s. The TVC loaded and saved programs over an ordinary
audio cassette recorder, and the `.cas` file is a byte-level representation of
one such tape rather than a recording of its audio.

This is a **knowledge-only** media entry: it captures a tape's program payload,
not a mountable filesystem, partition table, or archive. It is catalogued for
identification and cross-reference; no driver is planned. Disk-based TVC software
uses a separate image format, covered under [Videoton TVC disk](../disk/tvc.md).

## Structure

A `.cas` file begins with a fixed 144-byte (0x90) header that the MAME loader
parses for layout information. The first byte is a type/identification marker
(0x11 in the MAME reader). Within the header, a 16-bit little-endian field around
offset 0x82 records the size of the cassette data that follows, and nearby bytes
carry the file type and an autostart flag. The data body is split into sectors,
each protected by a CRC-16 checksum.

When MAME replays the image as audio it wraps the byte stream in the TVC's tape
framing: a leading silence, a long run of pilot (pre-data) cycles, a single sync
cycle, the encoded header and data sectors, and trailing post-data cycles, with
bits encoded by frequency-shift keying (distinct tone frequencies for 0 and 1
bits). That framing is a property of the playback path; the `.cas` file itself is
the structured header-plus-sectors container described above.

## References

- MAME loader: [`src/lib/formats/tvc_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/tvc_cas.cpp)
- [TVC — VIDEOTON TV-Computer (project site, English)](http://tvc.homeserver.hu/html/inenglish.html)
- [hightower70/tvc-tape — Videoton TV Computer Tape File Converter](https://github.com/hightower70/tvc-tape)
