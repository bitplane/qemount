# Plan

## 1. Flesh it out

- [ ] a common interface
  - [x] `/mnt/b1` `/mnt/b2` `/mnt/c` etc for partitioned disks + images
  - [ ] `/sbin/init.$mode` executed when `-m` is passed to the command line
    - [ ] Fix this in FreeBSD, but in a way that will actually work in future.
          Maybe have a shell?
- [ ] Python build system
  - [ ] carefully think about caching strategy

## 2. Link it in

- [x] client library
  - [x] detection
    - [ ] image file
    - [x] partition format
    - [x] file system
    - [ ] nested detection
  - [ ] qemu wrapper lib
- [ ] filesystem catalogue
  - [x] documentation as code (front-matter)
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
    - [ ] data builder for fileystems (27/43)
    - [ ] create some machine-like images
    - [ ] test runner and rules (architecture, design, mvp)
- [ ] fix bugs
  - [ ] simple9p
    - [x] .U + symlink support
    - [ ] fewer segfaults
  - [ ] 9pfuse
    - [ ] spam in file browser (unsupported modes)
  - [ ] Linux runner
    - [ ] change virtserialport to virtconsole for consistency with NetBSD

## 4. Stretch goals

- [ ] add more guests
  - [ ] AROS
  - [ ] Haiku
  - [ ] Atari ST (STEEM?)
  - [ ] OpenDarwin

