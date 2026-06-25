# Deferred code work

Dev-ticket-level queue of format docs that look feasible to implement as a
`mkfs` generator and/or an unpacker/unwrap driver (the pass-2/pass-3 work).
One line per item, added during the import. Picked up separately, later.

Format: `format/<cat>/<name> — <what's feasible / notes>`

---
format/disk/2d — mkfs feasible: 320KB fixed 2D geometry, headerless raw (no unwrap needed). File extraction would need Sharp Hu-BASIC fs (separate fs/ work).
