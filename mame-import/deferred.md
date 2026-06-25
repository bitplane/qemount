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
