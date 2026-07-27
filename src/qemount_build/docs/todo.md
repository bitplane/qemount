# Plan

## 1. Flesh it out

- [ ] a common interface
  - [x] export the guest namespace by default: `/` on POSIX, mounted DOS
        volumes beneath a synthetic `/` on AROS
  - [x] mount POSIX guest disks at `/mnt/b1`, `/mnt/b2`, `/mnt/c`, etc.
  - [ ] `/sbin/init.$mode` executed when `-m` is passed to the command line
    - [ ] Fix this in NetBSD, but in a way that will actually work in future.
          Maybe have a shell?
- [ ] Python build system
  - [ ] carefully think about caching strategy
  - [x] stream container output during long builds while retaining per-stage
        logs for failure reports

## 2. Link it in

- [x] client library
  - [x] detection
    - [x] image file
    - [x] partition format
    - [x] file system
    - [x] nested detection
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
    - [x] platform filesystem discovery
    - [ ] move harness server ports outside Linux's ephemeral port range
    - [ ] fewer segfaults
  - [ ] 9pfuse
    - [x] configurable outstanding-request limit for constrained transports
    - [ ] spam in file browser (unsupported modes)
  - [x] Linux runner
    - [x] change virtserialport to virtconsole for consistency with NetBSD

## 4. Stretch goals

- [ ] add more guests
  - [x] AROS
  - [ ] Haiku
  - [ ] Atari ST (STEEM?)
  - [ ] OpenDarwin
