---
title: MacOSX 11.3 SDK
urls:
  - https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.3.sdk.tar.xz
  - https://archive.org/download/mac-osx-11.3.sdk/MacOSX11.3.sdk.tar.xz
provides:
  - sources/MacOSX11.3.sdk.tar.xz
---

# MacOSX 11.3 SDK

macOS 11.3 SDK extracted from Xcode, used as the sysroot for cross-compiling
mac binaries with zig. Provides libSystem (.tbd stubs), C/POSIX headers, and
~200 system frameworks (CoreFoundation, IOKit, Foundation, Hypervisor,
ApplicationServices, etc.) for both `x86_64-macos` and `arm64-macos` targets.

Apple does not permit redistribution of the SDK, so it is not bundled with
this project — the downloader fetches it on demand. Users are responsible
for ensuring their use complies with the Xcode SDK license.

11.3 is chosen because it is the last release in the phracker mirror that
covers both Intel and Apple Silicon while still using the modern TBD v4
format that lld understands.

Tarball SHA256: `cd4f08a75577145b8f05245a2975f7c81401d75e9535dcffbb879ee1deefcbf4`
