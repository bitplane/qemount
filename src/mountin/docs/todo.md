# Plan

## 1. Flesh it out

- [ ] a common interface
  - [ ] `/sbin/init.$mode` executed when `-m` is passed to the command line
    - [ ] Fix this in NetBSD, but in a way that will actually work in future.
          Maybe have a shell?
- [ ] Python build system
  - [x] replace the macOS SDK in PureDarwin guest builds
    - [x] install open-source Darwin headers and libraries as a reusable sysroot
    - [x] publish the sysroot and compiler driver as the PureDarwin toolbox
    - [x] build 9d and mountin-init without the Apple SDK
    - [x] prove both binaries inside the PureDarwin guest
  - [ ] define one minimal headless QEMU feature profile across host platforms
    - [ ] build macOS-hosted QEMU against the PureDarwin toolbox instead of the
          Apple SDK
    - [ ] measure the size, build-time and acceleration trade-offs
  - [ ] carefully think about caching strategy
  - [ ] guest architecture coverage
    - [x] enable KVM in Linux-hosted QEMU builds
      - [ ] harden automatic `/dev/kvm` access against hostile build sources
    - [ ] cross-compiling
      - [ ] Linux 6.12
      - [ ] Linux 2.6
      - [ ] Haiku
      - [ ] AROS
    - [ ] add an aarch64 kernel configuration and QEMU boot path for NetBSD
    - [ ] define fallback policy for guests that only support x86

## 2. Link it in

- [ ] client library
  - [ ] qemu wrapper lib
- [ ] filesystem catalogue
  - [ ] site generator
- [ ] clients
  - [ ] FUSE
  - [ ] PeaZip
  - [ ] 7-zip
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
  - [ ] Atari ST
  - [ ] RISC OS
- [ ] bundle source
  - [ ] firstly, download source packages into builder images for archival
        purposes
  - [ ] later, make our own generic builder that can build everything including
        most of itself, forcing purity across every part of the platform
