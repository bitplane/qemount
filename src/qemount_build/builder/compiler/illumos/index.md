---
title: illumos compiler
build_platforms:
  x86_64-linux: {}
output_platforms:
  x86_64-illumos:
    provides:
      - docker:builder/compiler/illumos
build_requires:
  - sources/binutils-2.46.1.tar.bz2
  - sources/illumos-gate-linux-build.tar.gz
  - bin/${BUILD_ARCH}-linux-gnu/dmake
  - bin/${BUILD_ARCH}-linux-gnu/lib/libmakestate.so.1
  - bin/${BUILD_ARCH}-linux-gnu/lib/64/libelf.so.1
---

# illumos compiler

Linux-native build environment for illumos targets. It bootstraps only the
host tools required by kernel and appliance builds; target selection belongs
to downstream providers and does not require a full illumos world.
