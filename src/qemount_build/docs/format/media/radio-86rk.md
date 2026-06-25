---
title: Radio-86RK cassette image
created: 1986
system: Radio-86RK and compatibles (Soviet 8080 family)
extensions: [".rk", ".rku", ".rk8", ".rks", ".rko", ".rkr", ".rka", ".rkm", ".rkp", ".gam", ".g16", ".pki"]
aliases:
  - RK86
  - rk_cas
  - Mikrosha
  - Apogee BK-01
  - Partner 01.01
  - Krista
---

# Radio-86RK cassette image

A cassette image for the **Radio-86RK** and the family of Soviet 8-bit machines
derived from it. The Radio-86RK ("RK" = *radio-amateur computer*) was a
build-it-yourself design published in *Radio* magazine from 1986, based on a
KR580VM80A (an Intel 8080A clone). Its architecture was widely cloned, giving a
whole compatible family: the industrially-made **Mikrosha** (Lianozovo
Electromechanical Plant), **Apogee BK-01**, **Partner 01.01**, **Krista**,
**Alpha-BK**, **Impuls-02**, **Spectrum 001** and others, most retaining
backward compatibility with Radio-86RK software.

This is a **knowledge-only** entry. An RK cassette image is the byte stream of a
loaded program, not a mountable filesystem, so there is nothing to mount. It is
catalogued for identification and cross-reference across the RK-compatible
family; no driver is planned.

## Structure

Per MAME's loader, the image is a near-raw program dump that the loader frames
and modulates for tape:

- A 256-byte run of `0x00` leader precedes the data (`RK_HEADER_LEN`).
- For the standard RK variants a single `0xE6` sync byte follows the leader;
  the GAM sub-variant omits this and frames its data slightly differently.
- The remainder is the program payload.

MAME selects bit timing per variant (roughly 20, 22 or 60 samples per bit),
reflecting that different RK descendants recorded at different speeds — programs
often had to be tuned to the target machine. Extensions distinguish the
variants: `.rk`/`.rku`/`.rks`/`.rko`/`.rkr`/`.rka`/`.rkp` (20-sample RK20),
`.rkm` (22-sample RK22), `.rk8` (60-sample RK60), and `.gam`/`.g16`/`.pki`
(GAM). These are tape-synthesis parameters rather than on-disk magic, and the
256-byte zero leader is not a reliable signature, so there is no Detection
section.

## References

- MAME loader: [`src/lib/formats/rk_cas.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/rk_cas.cpp)
- [Radio-86RK — Wikipedia](https://en.wikipedia.org/wiki/Radio-86RK)
- [skiselev/radio-86rk — re-make and documentation](https://github.com/skiselev/radio-86rk)
- [Microsha, Krista, Apogee, Lviv — first Soviet home computers (Sudo Null)](https://sudonull.com/post/15272-Microsha-Krista-Apogee-Lviv-the-first-Soviet-computers-to-take-away)
- [Mikrosha — oldcomputer.info](https://oldcomputer.info/8bit/mikrosha/index.htm)
