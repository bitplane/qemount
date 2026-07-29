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
    - [ ] data builder for fileystems (27/43)
    - [ ] create some machine-like images
    - [ ] test runner and rules (architecture, design, mvp)
- [ ] fix bugs
  - [ ] 9pfuse
    - [ ] spam in file browser (unsupported modes)
  - [ ] AROS guest
    - [x] replace the 75 MiB pruned Live CD with a roughly 3 MiB allowlisted
          guest image
    - [ ] mount supported filesystems from raw, MBR and GPT images
    - [ ] investigate the MBR test image stalling guest startup

## 4. Stretch goals

- [ ] add more guests
  - [ ] Haiku
  - [ ] Atari ST (STEEM?)
  - [ ] OpenDarwin
