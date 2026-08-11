---
title: PureDarwin BaseSystem
requires:
  - sources/applefilesystemdriver-23.tar.gz
  - sources/compiler-rt-14.0.6.src.tar.xz
  - sources/libc-1244.30.3.tar.gz
  - sources/libdispatch-913.30.4.tar.gz
  - sources/libmalloc-140.40.1.tar.gz
  - sources/libplatform-161.20.1.tar.gz
  - sources/libpthread-301.30.1.tar.gz
  - sources/ioatafamily-255.tar.gz
  - sources/iopcifamily-320.30.2.tar.gz
  - sources/iostoragefamily-218.30.1.tar.gz
  - sources/hfs-407.30.1.tar.gz
  - sources/puredarwin-linux-build.tar.gz
  - sources/xnu-4570.41.2.tar.gz
provides:
  - bin/qemu/${OUTPUT_ARCH}-darwin/puredarwin/system/base-system.tar.gz
---

# PureDarwin BaseSystem

Builds the Darwin 17.4 XNU source in PureDarwin's Linux-hosted Clang/LLVM
environment and packages the kernel and QEMU PC platform driver closure as an
installable BaseSystem tree.

Source extraction, generated host tools, and target objects are cached by
source archive hashes so iterative toolchain work resumes from the last
successful object.
