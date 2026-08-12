---
title: PureDarwin BaseSystem
requires:
  - sources/architecture-268.tar.gz
  - sources/applefilesystemdriver-23.tar.gz
  - sources/applei386pci-6.tar.gz
  - sources/compiler-rt-14.0.6.src.tar.xz
  - sources/dyld-519.2.2.tar.gz
  - sources/libc-1244.30.3.tar.gz
  - sources/libcxx-5.0.0.src.tar.xz
  - sources/libcxxabi-5.0.0.src.tar.xz
  - sources/libdispatch-913.30.4.tar.gz
  - sources/launchd-842.92.1.tar.gz
  - sources/libinfo-517.30.1.tar.gz
  - sources/libm-2026.tar.gz
  - sources/libnotify-172.tar.gz
  - sources/libmalloc-140.40.1.tar.gz
  - sources/libplatform-161.20.1.tar.gz
  - sources/libpthread-301.30.1.tar.gz
  - sources/libresolv-65.tar.gz
  - sources/libsystem-1252.50.4.tar.gz
  - sources/libunwind-5.0.0.src.tar.xz
  - sources/ioatafamily-255.tar.gz
  - sources/ioatablockstorage-130.3.1.tar.gz
  - sources/iopcifamily-320.30.2.tar.gz
  - sources/iostoragefamily-218.30.1.tar.gz
  - sources/hfs-407.30.1.tar.gz
  - sources/puredarwin-qemount-0.2.tar.gz
  - sources/syslog-356.50.1.tar.gz
  - sources/xnu-4570.41.2.tar.gz
provides:
  - bin/qemu/${OUTPUT_ARCH}-darwin/puredarwin/system/base-system.tar.gz
---

# PureDarwin BaseSystem

Builds the Darwin 17.4 XNU source in PureDarwin's Linux-hosted Clang/LLVM
environment and packages the kernel and generic PC platform driver closure as an
installable BaseSystem tree.

The archive includes the source-built dynamic loader, libSystem umbrella and
its runtime-library closure, so it can start Darwin executables without
borrowing userland binaries from a prebuilt image.

Source extraction, generated host tools, and target objects are cached by
source archive hashes so iterative toolchain work resumes from the last
successful object.
