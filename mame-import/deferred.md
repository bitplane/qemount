# Deferred code work

Dev-ticket-level queue of format docs that look feasible to implement as a
`mkfs` generator and/or an unpacker/unwrap driver (the pass-2/pass-3 work).
One line per item, added during the import. Picked up separately, later.

Format: `format/<cat>/<name> — <what's feasible / notes>`

---
format/disk/apridisk — unwrap: 128-byte header + typed RLE records → raw sectors.
format/disk/atr — unwrap: strip 16-byte ATR header → raw Atari 8-bit sectors (XFD/DSK already raw).
format/disk/commodore-cbm — CBM DOS filesystem reader feasible: .d64/.d67 are decoded sector images, mountable via a 1541/CBM-DOS reader.
format/disk/ccvf — unwrap: parse the text/hex CCVF container → rebuild raw 128-byte sectors.
format/disk/cqm — unwrap: 133-byte header + signed-length RLE → raw sector image.
format/disk/d88 — unwrap: header + track-offset table + per-sector headers → ordered raw sectors.
format/disk/dcp — unwrap: 0xA3 header + track map → expand present tracks to full raw image.
format/disk/commodore-disk — CBM DOS filesystem reader feasible (BAM/directory on info track, 256-byte blocks).
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
format/disk/hpi — raw-sector image; HPDir/imgtool round-trip these; unpacker via fs/hp98x5 or fs/hp-lif feasible
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
format/disk/roland-sdisk — wd177x DSDD 80/2/9x512 MFM fixed geometry; mkfs feasible
format/disk/akai-s900 — fixed-geometry MFM 80/2/5x1024 (+ HD 10 sec); mkfs feasible
format/disk/rx01 — raw 77/1/26x128 FM dump; mkfs trivial (size-defined)
format/disk/rx50 — raw 80/1/10x512 MFM dump; mkfs trivial (size-defined)
format/arc/rpk — ZIP + layout.xml; unpacker feasible (unzip + parse XML socket map)
format/disk/sap — unpacker feasible: 66-byte header, per-sector framing, XOR 0xB3 + CRC; mkfs feasible
format/disk/sdf — unpacker feasible: SDF1 header + per-track records to raw MFM track image; mkfs feasible
format/disk/sf7000 — mkfs feasible: fixed 40/1/16/256 MFM sector image (163,840 B)
format/disk/sdd — mkfs feasible: headerless 256-byte-sector dump, size-keyed geometry
format/disk/st — mkfs feasible: raw GEMDOS/FAT sector image, geometries from BPB/size
format/disk/svi — mkfs feasible: fixed geometry, mixed FM 18x128 boot track + MFM 17x256
format/disk/swd — mkfs feasible: fixed 80/2/16x256 MFM geometry, side# 1/2 offset quirk
format/disk/tandy2000 — loop-mount/mkfs trivial: fixed 80/2/9/512 (720K) raw FAT12 image
format/disk/thom — mkfs feasible: 5 fixed FM/MFM geometries keyed by size
format/disk/ti99 — SDF (v9t9) raw dump → mkfs/reader feasible; TI FS (VIB + FDR chains) extraction feasible; TDF needs track decode
format/disk/tibdd001 — loop-mount/mkfs trivial: fixed 80/2/9/512 (720K) raw FAT/DOS image
format/disk/tiki100 — raw FM/MFM sector dump, fixed geometries; mkfs + reader feasible
format/disk/tim011 — single 800K MFM sector dump; mkfs feasible
format/disk/trd — raw TR-DOS sector image; mkfs (blank TR-DOS disk) + SCL->TRD expander feasible; pairs with disk/scl
format/disk/trs80 — JV1 trivial sector dump; JV3 descriptor-table parser feasible
format/disk/tvc — raw fixed-geometry 360K/720K MFM image; mkfs feasible
format/disk/uniflex — reader feasible: parse SIR at 0x200 + FDN area for a Unix-like directory/file walk
format/disk/vdk — strip variable header (dk + len word) then flat MFM sectors; unpacker straightforward
format/disk/vector06 — raw fixed-geometry (80/82x2x5x1024) sector dump; mkfs trivial
format/disk/vgi — raw 275-byte-sector Micropolis dump; unpacker can strip framing to recover 256-byte data
format/disk/victor9k — .img is ordered 512-byte sector dump; zoned geometry known; sector extraction straightforward
format/disk/vtech-disk — .bin/.dsk decode to 128-byte sectors on 40x16 SS geometry; reuses fs/vtech layout; mkfs feasible
format/disk/wren — fixed 200K SSDD sector dump; mkfs + CP/M unpacker feasible
format/disk/x68000-xdf — fixed 1232K 2HD sector dump; mkfs + Human68k FAT unpacker feasible
