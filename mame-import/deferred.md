# Deferred code work

Dev-ticket-level queue of format docs that look feasible to implement as a
`mkfs` generator and/or an unpacker/unwrap driver (the pass-2/pass-3 work).
One line per item, added during the import. Picked up separately, later.

Format: `format/<cat>/<name> — <what's feasible / notes>`

---
format/disk/2d — mkfs feasible: 320KB fixed 2D geometry, headerless raw (no unwrap needed). File extraction would need Sharp Hu-BASIC fs (separate fs/ work).
format/disk/86f — unwrap feasible from the 86Box spec but complex (FM/MFM surface decode, weak-bit handling) → raw sectors. mkfs feasible.
format/disk/abc800i — deinterleave to a linear sector image feasible (interleave tables in the MAME loader).
format/media/adam-ddp — unwrap feasible: HE/GW directory + per-block checksums documented; decode the DDP tape structure to a linear EOS block image (shared with disk/adam).
format/disk/aim — MFM track decode → sector image feasible (index marks + sector headers per MAME loader).
format/disk/apple2 — nibble formats (.nib/.edd) GCR decode → sector image feasible.
format/disk/apple-gcr — GCR (zoned) decode → raw sectors; 2IMG/2MG header strip feasible.
format/disk/apd — decompress (gzip) + decode SD/DD/QD track bitstreams → raw sectors feasible (flux-level, complex).
format/disk/apridisk — unwrap: 128-byte header + typed RLE records → raw sectors.
format/disk/atr — unwrap: strip 16-byte ATR header → raw Atari 8-bit sectors (XFD/DSK already raw).
format/disk/commodore-cbm — CBM DOS filesystem reader feasible: .d64/.d67 are decoded sector images, mountable via a 1541/CBM-DOS reader.
format/disk/ccvf — unwrap: parse the text/hex CCVF container → rebuild raw 128-byte sectors.
