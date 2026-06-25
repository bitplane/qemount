---
title: RPK (ROM PacK) cartridge container
created: unknown
system: TI-99/4A and other cartridge-based machines (MAME / MESS)
extensions: [".rpk"]
aliases: [rpk, "RomPacK", "ROM Pack cartridge"]
related:
  - format/arc/zip
  - format/disk/ti99
  - format/disk/tibdd001
---

RPK ("ROM PacK") is the cartridge container format used by MAME's
software lists, most prominently for the Texas Instruments TI-99/4A but
also for other cartridge-based machines. Unlike a flat ROM dump, an RPK
bundles the individual chip dumps from a cartridge together with a
machine-readable description of how those chips are wired onto the
cartridge's printed circuit board.

Structurally an RPK file is an ordinary ZIP archive with the extension
changed to `.rpk`. Inside the archive are:

- one or more binary ROM/RAM dump files, and
- a mandatory `layout.xml` describing the cartridge.

The `layout.xml` is rooted at a `<romset>` element. A `<resources>`
section declares each dump as a `<rom>` or `<ram>` resource (with a file
reference and optional CRC/SHA1 hash), and a `<configuration>` section
names the PCB `<pcb type=...>` and lists `<socket>` elements. Each
socket carries an `id` and a `uses` attribute that binds a board socket
to one of the declared resources, so the emulator can map each dump to
the correct address space and banking behaviour. PCB types seen for the
TI-99/4A include `standard`, `paged`, `minimem` (MiniMemory), `super`
(SuperSpace II), `mbx`, and `gromemu`/persistent-RAM variants. The
persistent-RAM case lets a cartridge's battery-backed memory be saved
back to a file.

Because it carries a navigable ZIP directory plus an XML manifest that
maps dumps to hardware, RPK is a true structured container rather than an
opaque blob, which is why it is catalogued here under archives.

## Detection

An RPK is a ZIP archive, so it begins with the ZIP local-file-header
signature `PK\x03\x04` (`50 4B 03 04`). What distinguishes it from a
generic ZIP is the mandatory `layout.xml` member at the archive root;
MAME rejects an RPK that lacks it. Both the MAME loader and independent
community documentation agree on these two points.

## References

- MAME source: `src/lib/formats/rpk.cpp` (RPK reader: ZIP archive plus
  `layout.xml` with `<romset>` / `<resources>` / `<configuration>` and
  `<socket>` elements requiring `id` and `uses` attributes).
- Ninerpedia, "MESS cartridge handling":
  https://www.ninerpedia.org/wiki/MESS_cartridge_handling
- AtariAge forums, "RPK (RomPacK cartridge packs)":
  https://forums.atariage.com/topic/217690-rpk-rompack-cartridge-packs/
- NinerMAME, "Creating cartridges":
  https://www.ninermame.org/setup/newcarts
