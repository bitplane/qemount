# Plan

## 1. Flesh it out

- [ ] a common interface
  - [ ] `/sbin/init.$mode` executed when `-m` is passed to the command line
    - [ ] Fix this in NetBSD, but in a way that will actually work in future.
          Maybe have a shell?
- [ ] Python build system
  - [ ] carefully think about caching strategy
    - [ ] lock the build directory so concurrent qemount-build processes cannot
      corrupt shared caches or interleave output
    - [x] separate qemount binaries from the compiled catalogue so catalogue
      changes do not rebuild the Rust code
    - [ ] decouple downloaded source identity from the downloader image hash
      before changing the downloader again; downloader changes currently
      invalidate every source, redownload upstream archives, and rebuild all
      downstream targets
    - [ ] migrate valid source cache entries without redownloading, then test
      downloader changes, source-ref changes, missing outputs, and failed
      atomic downloads separately
  - [ ] guest architecture coverage
    - [x] enable KVM in Linux-hosted QEMU builds
      - [ ] harden automatic `/dev/kvm` access against hostile build sources
    - [ ] cross-compiling
      - [ ] Linux 6.12
      - [ ] Linux 2.6
      - [ ] Haiku
      - [ ] AROS
      - [ ] PureDarwin (upgrade to latest Darwin + fork)
    - [ ] add an aarch64 kernel configuration and QEMU boot path for NetBSD
    - [ ] define fallback policy for guests that only support x86
  - [ ] reduce size of Dragonfly BSD

## 2. Link it in

- [ ] client library
  - [ ] qemu wrapper lib
- [ ] filesystem catalogue
  - [ ] site generator
- [ ] clients
  - [ ] FUSE
  - [ ] 7zip
  - [ ] extractor

## 3. Polish the turd

- [ ] install scripts
  - [ ] add installers
  - [ ] xdg launcher
- [ ] safety
  - [ ] test data + framework
    - [ ] data builder for filesystems (51/91)
    - [ ] create some machine-like images
    - [ ] test runner and rules (architecture, design, mvp)
- [ ] fix bugs
  - [ ] 9pfuse
    - [ ] spam in file browser (unsupported modes)

## 4. Stretch goals

- [ ] add more guests
  - [ ] Atari ST (STEEM?)
  - [ ] 9front
  - [ ] RISC OS
  - [ ] illumos
