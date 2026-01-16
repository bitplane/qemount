# Plan

## 1. Flesh it out

- [x] more guests
  - [x] Linux 2.6
  - [x] NetBSD 10
- [ ] a common interface
  - [x] `/mnt/b1` `/mnt/b2` `/mnt/c` etc for partitioned disks + images
  - [ ] `/sbin/init.$mode` executed when `-m` is passed to the command line
    - [ ] Fix this in FreeBSD, but in a way that will actually work in future
          maybe have a shell

## 2. Link it in

- [ ] client library
  - [ ] detection
    - [ ] file type
    - [ ] partition format
    - [ ] file system
  - [ ] qemu wrapper lib
- [ ] filesystem catalogue
  - [ ] documentation as code (front-matter)
  - [ ] site generator
- [ ] clients
  - [x] FUSE
  - [ ] 7zip
  - [ ] extractor

## 3. Polish the turd

- [ ] build and install scripts
  - [ ] write an installer
  - [ ] xdg launcher
- [ ] safety
  - [ ] mount read only by default
  - [ ] test data + framework
    - [ ] data builder for fileystems (27/43)
    - [x] break archives out into a separate path
    - [ ] create some machine-like images
    - [ ] test runner and rules (architecture, design, mvp)
- [ ] fix bugs
  - [ ] simple9p
    - [x] .U + symlink support
    - [ ] fewer segfaults
  - [ ] 9pfuse
    - [x] block size wrong for `du`
    - [ ] spam in file browser (unsupported modes)
  - [ ] Linux runner
    - [ ] change virtserialport to virtconsole for consistency with NetBSD
  - [ ] Build system
    - [ ] Download + cache system with automatic cache blowing
    - [x] Export builder images for long term archival (archive.org)

## 4. Stretch goals

- [ ] add more guests
  - [ ] AROS
  - [ ] Haiku
  - [ ] Atari ST (STEEM?)
  - [ ] OpenDarwin

