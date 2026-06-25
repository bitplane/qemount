# MAME format import

A long-running, hand-driven effort to mine MAME's disk/floppy/media format
loaders into our format catalogue (`src/qemount_build/docs/format/`). MAME has
one of the best collections of obscure-format knowledge in existence; this turns
that knowledge into catalogue pages and cross-references.

**This directory is temporary scaffolding.** It is committed only so the work is
shareable and resumable across machines/people/agents. Delete it when the import
is finished — the permanent output is the catalogue docs themselves.

## How to run a batch

A human says "process the next N" when they have spare token budget. Any agent
(Claude, Codex, whoever) can do it from a fresh clone. There is no script — you
read `worklist.md`, process items from the **top**, and trim them as you go.

For each format at the top of `worklist.md`:

1. **Read the MAME source.** Open `src/lib/formats/<file>.cpp` and its matching
   `.h` on GitHub:
   `https://github.com/mamedev/mame/blob/master/src/lib/formats/<file>`
   Work out what the format actually is.

2. **Evaluate scope** (see *Scope* below).
   - **Out of scope** → delete the line from `worklist.md`, move on. No log, no
     note. The list only shrinks.

3. **Do we already have it?** Search **the whole** `src/qemount_build/docs/format/`
   tree — **all** categories (`disk/ fs/ pt/ arc/ media/`), not just the obvious
   one — by the format's name, its aliases, its extensions, **and the system /
   platform name**. A format is often already present at a *different layer*
   (e.g. Acorn was covered under `fs/adfs` and `pt/acorn/` long before the
   `disk/acorn` image format existed). Use a recursive grep over the full tree,
   e.g. `grep -ril acorn src/qemount_build/docs/format/`.
   - **Yes** → add a one-line note under the existing doc's `## References`
     linking the MAME source (`src/lib/formats/<file>.cpp`). Delete the line.
     Done.
   - **No** → continue.

4. **Research and write the doc.** Find independent information on the web (what
   it is, the system, the year, extensions, structure). Write a new page at
   `src/qemount_build/docs/format/<cat>/<name>.md` using the *Frontmatter
   schema* and prose **in your own words**, citing the MAME source link and the
   web sources under `## References`.
   - **Magic bytes:** document them in a `## Detection` prose section **only if
     at least two independent sources agree** on them. Do **not** add a
     `detect:` frontmatter rule in this pass — see *Why no detect rules yet*.
   - **Headerless formats are normal.** Many `*_dsk` formats are raw,
     fixed-geometry sector dumps with no magic at all (e.g. `disk/2d`).
     That's fine — describe the geometry and omit the Detection section. Do not
     invent a size-based rule; exact-size matching collides badly.

5. **Note deferred code work.** If a `mkfs` generator and/or an unpacker looks
   feasible from the information available, add one line to `deferred.md`:
   `format/<cat>/<name> — <short note on what's feasible>`.

6. **Pop it.** Delete the line from `worklist.md`. Next.

Commit each processed format as one commit (doc/annotation + the `worklist.md`
trim together) so the git history is its own audit trail:
`mame-import: <name>`.

## The STOP rule (the one hard rule)

If you cannot tell what the format is, cannot decide scope, or cannot find
enough independent information to write an **honest** doc, **STOP and report
it**. Leave the line in `worklist.md`. Never invent a date, a history, a magic
signature, or a provenance to keep the loop moving. A missing entry is fine; a
fabricated one poisons the catalogue.

## Scope

The test is **structure, not subject matter**. A format earns a doc if it has
navigable structure a reader can use — a header, magic, metadata, offsets, or a
page / sector / directory table. If it is an opaque blob with no internal
structure (identified only by its size or extension, payload not navigable), it
is not a format: delete it and move on. Read the MAME source to decide — the
parser shows you exactly what structure (if any) the format has.

Applying that:

- **IN** — anything structured that holds data: disk/floppy images (`*_dsk`,
  including flux/surface formats like `86f`/`ipf` — their track and flux tables
  *are* structure), filesystems (`fs_*`), partition tables, archives.
- **Structured but not mountable → `media/` knowledge entry** — tape/cassette,
  optical-audio, or program-load images that have a real header/page table but
  no filesystem to mount (e.g. `media/supercharger`: a load header at `0x2000`
  with a page table). Catalogue for identification and cross-reference; mark
  no-driver (no `deferred.md` entry).
- **OUT (delete)** — three kinds:
  - opaque blobs with no navigable structure (a bare ROM dump that is just code
    bytes; raw audio with no framing);
  - **generic, ubiquitous interchange codecs** that MAME only uses as cassette
    I/O plumbing rather than as a system's own storage format — AIFF, WAV, FLAC
    (`aiffile`, `wavfile`, `flacfile`). Structure is necessary but **not
    sufficient**: these are structured yet still out, because they are general
    audio containers, not an obscure system's format;
  - MAME infrastructure that isn't a format at all (`flopimg`, `fsmgr`,
    `all.cpp`, helpers).
- Genuinely unsure after reading the source → **STOP and flag**, don't guess.

## Category (sets the path `docs/format/<cat>/<name>.md`)

- decodes to a raw disk/floppy image → `disk/`
- is the on-media filesystem layout itself → `fs/`
- partitions or splits a disk into volumes → `pt/`
- is an archive of files → `arc/`
- is a raw optical/tape/cartridge/flux capture → `media/`

## Frontmatter schema (pass 1 — note: NO `detect:`)

```yaml
---
title: <Human-readable name>
created: <year, or "unknown">
system: <platform / era, e.g. "ZX Spectrum">
extensions: [".ext"]      # file extensions, if any
aliases: [<other names>]  # so future dedup finds it; omit if none
related:
  - format/<cat>/<name>   # cross-references to sibling/lineage formats
---
```

Then prose: what it is, the system and era, structure, and a `## References`
section linking the MAME source and the web sources used. Add a `## Detection`
section with the magic bytes **only** when ≥2 sources agree (prose, not a rule).

`related:` entries may point to formats **not yet imported** (e.g. a sibling
still in `worklist.md`). That's fine and encouraged — it flags the sibling and
builds the cross-reference graph as the catalogue fills in.

## Why no `detect:` rules yet

A `detect:` frontmatter rule is what actually drives our format detector, and a
wrong one silently mis-identifies real images. We can't verify rules in this pass
(we don't have the proprietary test images), and overlapping magics across a
growing catalogue collide. So pass 1 is **knowledge only** — magic bytes live in
prose. Functional `detect:` rules are a **second pass**, added later when we have
a real test image to run through `detect`. A doc with no `detect:` is simply not
compiled into the detector (`compile.py` skips it), so this is safe.

## Attribution

Facts aren't copyrightable; verbatim text and tables are. Write everything in
your own words. Always cite the MAME source file you read, plus any web sources,
under `## References`.
