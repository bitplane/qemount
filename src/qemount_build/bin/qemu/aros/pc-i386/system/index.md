---
title: AROS PC i386 System
requires:
  - sources/aros-qemount-2026-07-30.tar.gz
  - sources/aros-ports/acpica-unix-20260408.tar.gz
  - sources/aros-ports/boost_1_89_0.tar.gz
  - sources/aros-ports/bzip2-1.0.8.tar.gz
  - sources/aros-ports/codesets/6.22.tar.gz
  - sources/aros-ports/de265/v1.0.16.tar.gz
  - sources/aros-ports/expat-2.8.2.tar.bz2
  - sources/aros-ports/freetype-2.14.3.tar.xz
  - sources/aros-ports/ftdmo2143.zip
  - sources/aros-ports/glu-9.0.2.tar.xz
  - sources/aros-ports/grub-2.12.tar.gz
  - sources/aros-ports/heif/v1.19.8.tar.gz
  - sources/aros-ports/jpegsrc.v9f.tar.gz
  - sources/aros-ports/libaom-3.12.1.tar.gz
  - sources/aros-ports/libpng-1.6.58.tar.gz
  - sources/aros-ports/libwebp-1.5.0.tar.gz
  - sources/aros-ports/mesa-20.0.8.tar.xz
  - sources/aros-ports/pci.ids
  - sources/aros-ports/tiff-4.7.2.tar.xz
  - sources/aros-ports/utf8proc/v2.11.3.tar.gz
  - sources/aros-ports/xz-5.8.3.tar.gz
  - sources/aros-ports/zlib.tar.gz
  - sources/aros-ports/zstd-1.5.7.tar.gz
provides:
  - bin/qemu/${ARCH}-aros/system/aros.iso
  - lib/${ARCH}-aros/sdk.tar.gz
---

# AROS PC i386 System

Builds the tiny-variant AROS system once, producing both its bootable base ISO
and the matching Developer SDK. Guest programs consume the SDK, and the final
guest image adds those programs to the base ISO without rebuilding AROS.
