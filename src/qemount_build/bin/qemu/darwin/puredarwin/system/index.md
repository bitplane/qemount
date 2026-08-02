---
title: PureDarwin XNU Kernel
requires:
  - sources/compiler-rt-14.0.6.src.tar.xz
  - sources/bootstrap_cmds-98.tar.gz
  - sources/libdispatch-913.30.4.tar.gz
  - sources/libplatform-161.20.1.tar.gz
  - sources/puredarwin-linux-build.tar.gz
  - sources/xnu-4570.41.2.tar.gz
provides:
  - bin/qemu/${ARCH}-darwin/puredarwin/system/kernel.tar.gz
---

# PureDarwin XNU Kernel

Builds the Darwin 17.4 XNU source in PureDarwin's Linux-hosted Clang/LLVM
environment and packages its installation tree. PureDarwin supplies the CMake
integration and open-source driver set. XNU, MIG from bootstrap_cmds,
libdispatch's kernel firehose and libplatform's atomic primitives are pinned to
Apple's matching macOS 10.13.3 source release.
Source extraction, generated host tools, and target objects are cached by source
archive hashes so iterative toolchain work resumes from the last successful
object.
