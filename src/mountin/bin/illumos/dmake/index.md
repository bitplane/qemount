---
title: illumos dmake
-output_platforms: true
output_platforms:
  x86_64-linux-gnu:
    build_platforms:
      x86_64-linux: {}
  aarch64-linux-gnu:
    build_platforms:
      aarch64-linux: {}
build_requires:
  - sources/schilytools-2024-03-21.tar.gz
  - sources/elfutils-0.194.tar.bz2
provides:
  - bin/${TARGET_PLATFORM}/dmake
  - bin/${TARGET_PLATFORM}/lib/libmakestate.so.1
  - bin/${TARGET_PLATFORM}/lib/64/libmakestate.so.1
  - bin/${TARGET_PLATFORM}/lib/64/libelf.so.1
---

# illumos dmake

Schily's portable SunPro-derived parallel make, built natively for the Linux
host. The linker support library used to maintain make-state dependencies is
installed in the native and 64-bit SunPro prefix locations.

The native prefix also carries a source-built elfutils `libelf`. illumos CTF
tools require archive iteration fixed after Debian bookworm's 0.188 release.
