---
title: PureDarwin XNU Kernel
requires:
  - sources/compiler-rt-14.0.6.src.tar.xz
  - sources/puredarwin-linux-build.tar.gz
provides:
  - bin/qemu/${OUTPUT_ARCH}-darwin/puredarwin/system/kernel.tar.gz
---

# PureDarwin XNU Kernel

Builds the XNU source vendored by PureDarwin in its Linux-hosted Clang/LLVM
environment and packages its installation tree. The kernel is a source-build
proof and is not installed into the appliance, whose published compatibility
substrate retains its matching kernel and drivers.

Source extraction, generated host tools, and target objects are cached by
source archive hashes so iterative toolchain work resumes from the last
successful object.
