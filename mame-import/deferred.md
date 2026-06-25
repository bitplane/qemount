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
format/disk/cqm — unwrap: 133-byte header + signed-length RLE → raw sector image.
format/disk/d88 — unwrap: header + track-offset table + per-sector headers → ordered raw sectors.
format/disk/dcp — unwrap: 0xA3 header + track map → expand present tracks to full raw image.
format/disk/commodore-disk — CBM DOS filesystem reader feasible (BAM/directory on info track, 256-byte blocks).
format/disk/dfi — flux decoder feasible: rescale DiscFerret flux deltas → FM/MFM sectors (complex, like IPF).
format/disk/dim — unwrap: strip 0x100 header → raw PC-98 sectors.
format/disk/dmk — converter: walk 16-byte header + per-track IDAM tables → raw sectors.
format/disk/cpc-dsk — reader: walk Disc/Track Information Blocks → extract raw sectors.
format/disk/dip — flat CHS reconstruction; unpacker + mkfs feasible (fixed 77/2/8/1024 geometry)
format/disk/fdd — Virtual98 VFD; sector-map fully documented incl. fill-byte decompression; unpacker + mkfs feasible
format/disk/esq8 — flat mixed-size sector dump; reader/mkfs feasible from geometry
format/disk/excali64 — flat WD177x dump; reader feasible (gap values unverified)
format/disk/fdos — fixed-geometry wd177x sector image; mkfs/reader feasible
format/disk/fl1 — fixed-geometry wd177x MFM image; mkfs feasible
format/disk/flex — documented linked-list FS + SIR; file-extraction unpacker feasible
format/disk/fmtowns — raw fixed-geometry (77/2/8/1024) dump; mkfs + sector unpacker straightforward
format/fs/cbmdos — mkfs + unpacker feasible; well-specified BAM/directory, MAME has a writer
format/fs/coco-os9 — mkfs + unpacker feasible; MAME PR #9434 adds formatting support
format/fs/coco-rsdos — mkfs + unpacker feasible; simple granule-FAT layout, MAME has a writer
format/fs/hp98x5 — unpacker (reader) feasible; writer more involved (multi-machine variants)
format/fs/hp-lif — mkfs + unpacker feasible; MAME implements full LIF read/write, 256-byte records
format/fs/isis — mkfs + unpacker feasible; linkage-block chaining + reserved system files add complexity
format/fs/oric-jasmin — mkfs + unpacker feasible; simple track-20 dir + bitmap + inode chains
format/fs/prodos — mkfs + unpacker feasible; well-documented, MAME read/write; seedling/sapling/tree/extended
format/fs/vtech — mkfs + unpacker feasible; full layout known (trk0 dir, 126+2 sector chains, sector-15 bitmap)
format/disk/fsd — FSD→SSD/sector extractor feasible (FSD magic + per-track/sector records)
format/disk/fz1 — raw sector extractor feasible from fixed geometry (80/2/8/1024)
format/disk/g64 — GCR→sector decode could recover CBM DOS blocks (D64-equivalent); non-trivial bitstream parse
format/disk/guab — raw sector extractor feasible from fixed WD177x geometry (80/2/18/256)
format/disk/h17disk — unpacker feasible: walk H17D tagged blocks, strip sector framing to raw data
format/disk/hector-disc2 — mkfs feasible: fixed-geometry basicdsk (3 variants)
format/disk/hector-minidisc — mkfs feasible: fixed uPD765 geometry 70/2/9/512
format/disk/hfe — reader/writer feasible; HxC2001-published header + track LUT + bitstream (v1/v2)
format/disk/hpi — raw-sector image; HPDir/imgtool round-trip these; unpacker via fs/hp98x5 or fs/hp-lif feasible
format/disk/hxcmfm — mkfs feasible (header + flat track-descriptor table, magic HXCMFM); unpacker needs MFM decode
format/disk/ibmxdf — unpacker feasible: fixed 3.5"HD geometry, mixed-size sectors per MAME tables; cyl0 plain FAT12
format/disk/idpart — mkfs/unpacker feasible: fixed 18/256 QD geometry (gaps unverified upstream)
format/disk/intel-mds — mkfs/unpacker feasible: two fixed geometries by size, FM vs MMFM
format/disk/iq151 — fixed 77/1/26/128 8" SSSD geometry; unpacker/mkfs feasible
format/disk/itt3030 — fixed DSDD wd177x geometry; unpacker/mkfs feasible
format/disk/juku — fixed 80/10/512 SS/DS wd177x geometry; unpacker/mkfs feasible
format/disk/jfd — reader feasible: JFDI header + gzip + track/sector/data tables; writer harder (protection metadata)
format/disk/jvc — feasible: sector dump + optional header (size = filelen % 256), geometry from header fields
format/disk/kaypro — feasible: raw 512-byte mkfs/unpacker, KAY1/KAY2 fixed geometry
format/disk/kc85 — feasible: raw sector mkfs/unpacker, 80/2 fixed geometry (3 sector layouts)
format/disk/lw30 — GCR sector image, fixed 78/1/12/256 geometry; extract/mkfs feasible
format/disk/m20 — raw 286720-byte mixed FM/MFM sector dump; extract/mkfs feasible
format/disk/m5 — raw fixed-geometry sector dumps (5.25" DSDD + 3" FD-5); extract/mkfs feasible
format/disk/mdos — fixed-geometry 8" FM sector dump; mkfs feasible
format/disk/mfi — flux reader/unpacker feasible (zlib + delta-packed cell decode), non-trivial
format/disk/mikromikko — fixed-geometry sector dump; mkfs feasible for MM1 (640 KB)
format/disk/ms0515 — fixed-geometry MFM sector dump; mkfs feasible
format/disk/msx — raw FAT12 sector image; mkfs feasible (standard 720K FAT12 BPB + MSX boot)
format/disk/mtx — raw CP/M sector image (256-byte sectors); mkfs feasible
format/disk/nabupc — raw CP/M sector image; mkfs feasible (DPB in track-0 gap not captured by plain layout)
format/disk/nanos — raw CP/M sector image; mkfs feasible (gap sizes unverified upstream)
format/disk/fds — block-structured; file-block extractor feasible (NESdev block types 1-4); mkfs from logical files feasible
format/disk/nfd — sector-map reader → raw/MFM conversion feasible (r0 fixed map; r1 needs track-index parse)
format/disk/nascom — fixed-geometry raw-dump mkfs feasible; CP/M variants reuse fs/cpm
format/disk/opd — fixed-geometry raw image; mkfs feasible (gap params unverified)
format/disk/naslite — raw image + deterministic interleave; round-trip converter feasible
format/disk/os9 — geometry-detected raw OS-9 image container; image writer feasible (reuses fs/coco-os9 layout)
format/disk/pc98 — raw PC-98 sectors; loop-mountable / sector extract feasible (no header to strip)
format/disk/pc98fdi — strip self-described header (hsize at 0x08, usually 4096) to recover raw image; mkfs feasible
format/disk/pc-img — raw 512B-sector PC floppy; loop-mountable; mkfs trivial from size→geometry table
format/disk/pk8020 — fixed-geometry CP/M sector dump (819200 bytes, 80/2/5/1024); mkfs + CP/M unpacker feasible
format/disk/poly — size-keyed CP/M geometries; mkfs + CP/M unpacker feasible
format/disk/pyldin — fixed 80/2/9/512 raw image; mkfs/extract straightforward once FS known
format/disk/ql — raw sector image; QDOS filesystem reader/extractor documented and implementable
format/disk/rc759 — fixed 77/2/8/1024 raw image; CP/M-86 directory extraction possible
