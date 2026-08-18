---
title: GitHub Binary Release
requires:
  - docker:builder/copy
runs_on: docker:builder/copy
output_platforms:
  neutral:
    provides:
      release/${MOUNTIN_RELEASE_REF}/github/lib/include/mountin.h:
        requires:
          - lib/include/mountin.h
  x86_64-linux-musl:
    provides:
      release/${MOUNTIN_RELEASE_REF}/github/lib/x86_64-linux-musl/libmountin.a:
        requires:
          - lib/x86_64-linux-musl/libmountin.a
      release/${MOUNTIN_RELEASE_REF}/github/bin/x86_64-linux-musl/detect:
        requires:
          - bin/x86_64-linux-musl/detect
  x86_64-linux-gnu:
    provides:
      release/${MOUNTIN_RELEASE_REF}/github/lib/x86_64-linux-gnu/libmountin.a:
        requires:
          - lib/x86_64-linux-gnu/libmountin.a
      release/${MOUNTIN_RELEASE_REF}/github/lib/x86_64-linux-gnu/libmountin.so:
        requires:
          - lib/x86_64-linux-gnu/libmountin.so
      release/${MOUNTIN_RELEASE_REF}/github/bin/x86_64-linux-gnu/detect:
        requires:
          - bin/x86_64-linux-gnu/detect
  aarch64-linux-musl:
    provides:
      release/${MOUNTIN_RELEASE_REF}/github/lib/aarch64-linux-musl/libmountin.a:
        requires:
          - lib/aarch64-linux-musl/libmountin.a
      release/${MOUNTIN_RELEASE_REF}/github/bin/aarch64-linux-musl/detect:
        requires:
          - bin/aarch64-linux-musl/detect
  aarch64-linux-gnu:
    provides:
      release/${MOUNTIN_RELEASE_REF}/github/lib/aarch64-linux-gnu/libmountin.a:
        requires:
          - lib/aarch64-linux-gnu/libmountin.a
      release/${MOUNTIN_RELEASE_REF}/github/lib/aarch64-linux-gnu/libmountin.so:
        requires:
          - lib/aarch64-linux-gnu/libmountin.so
      release/${MOUNTIN_RELEASE_REF}/github/bin/aarch64-linux-gnu/detect:
        requires:
          - bin/aarch64-linux-gnu/detect
  x86_64-windows-gnu:
    provides:
      release/${MOUNTIN_RELEASE_REF}/github/lib/x86_64-windows-gnu/mountin.lib:
        requires:
          - lib/x86_64-windows-gnu/mountin.lib
      release/${MOUNTIN_RELEASE_REF}/github/lib/x86_64-windows-gnu/mountin.dll:
        requires:
          - lib/x86_64-windows-gnu/mountin.dll
      release/${MOUNTIN_RELEASE_REF}/github/bin/x86_64-windows-gnu/detect.exe:
        requires:
          - bin/x86_64-windows-gnu/detect.exe
  x86_64-darwin:
    provides:
      release/${MOUNTIN_RELEASE_REF}/github/lib/x86_64-darwin/libmountin.a:
        requires:
          - lib/x86_64-darwin/libmountin.a
      release/${MOUNTIN_RELEASE_REF}/github/lib/x86_64-darwin/libmountin.dylib:
        requires:
          - lib/x86_64-darwin/libmountin.dylib
      release/${MOUNTIN_RELEASE_REF}/github/bin/x86_64-darwin/detect:
        requires:
          - bin/x86_64-darwin/detect
  aarch64-darwin:
    provides:
      release/${MOUNTIN_RELEASE_REF}/github/lib/aarch64-darwin/libmountin.a:
        requires:
          - lib/aarch64-darwin/libmountin.a
      release/${MOUNTIN_RELEASE_REF}/github/lib/aarch64-darwin/libmountin.dylib:
        requires:
          - lib/aarch64-darwin/libmountin.dylib
      release/${MOUNTIN_RELEASE_REF}/github/bin/aarch64-darwin/detect:
        requires:
          - bin/aarch64-darwin/detect
  wasm32-wasi:
    provides:
      release/${MOUNTIN_RELEASE_REF}/github/lib/wasm32-wasi/mountin.wasm:
        requires:
          - lib/wasm32-wasi/mountin.wasm
---

# GitHub Binary Release

Target-specific libmountin libraries, the public C header and detect binaries,
staged without renaming beneath their normal build paths.
