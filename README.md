# qemount

Let's mount everything/anything using qemu, by exposing it over 9p or other
transport. Spin up a tiny VM that provides access to an image, one instance
per mount.

* Have the ability to use kernel mounts in FUSE
* Run ancient Linux kernels that still had write access to now read-only
  filesystems
* Run old operating systems (Amiga, Acorn) with any CPU arch, and read/write
  their filesystems
* ... basically a clutch between any image/block device, URL, file and anything
  else, the UNIX way - everything is a file.

## STATUS

0: unstable / pre-alpha

## Usage

Currently there's:

* no filesystem catalogue
* no safety settings, everything is read/write even if it'll destroy disks
* no client library for cross platform access
* no packaging / install scripts

But there is:

* A FUSE client
* Linux 2.6 and 6.11 guests

To use it:

1. Install `podman`, `fuse`, `make` and `qemu`
2. Type `make` to build the Linux 2.6 and 6.11 guests.
3. Use `./build/run-qemu.sh` to start one of the guests with `-i some-image`
   and `-9p` to run the 9p init script.
4. Once it's started and is grumbling about not having a connection (not
   before), connect to it with the 9p FUSE client using:
   `build/clients/linux-fuse/x86_64/bin/9pfuse /tmp/9p.sock /some/mount/point`

If the stars align, you'll be able to mangle the files in your given disk image.

### plan

#### 0. Prove it works

- [x] prove it can be done and actually works
- [x] make a build system that isn't shit
- [x] get a working guest
  - [x] kernel + busybox image
  - [x] 9p server
- [x] make it go
  - [x] 9p client
  - [x] qemu wrapper script

#### 1. Flesh it out

- [x] untangle it
  - [x] fix testdata structure
  - [x] 9p server -> separate project
- [ ] more guests
  - [ ] AROS
  - [x] Linux 2.6
- [ ] build and install scripts
  - [ ] write an installer
  - [ ] xdg launcher

#### 2. Link it in

- [ ] client library
  - [ ] filesystem detector
  - [ ] qemu lib
  - [ ] filesystem catalogue
- [ ] clients
  - [x] FUSE
  - [ ] 7zip
  - [ ] extractor

#### 3. Polish the turd

- [ ] safety
  - [ ] mount read only by default
  - [ ] make a test framework
- [ ] fix bugs
  - [ ] simple9p
    - [ ] spam in file browser
  - [ ] FUSE
    - [ ] block size wrong for `du`
  - [ ] build
    - [ ] touch dockerfiles when deps change
    - [x] don't build targets unless they're needed

## Hacking

The project uses `podman` to build targets in builder images. There's a
`Dockerfile`, an `inputs.txt` and an `outputs.txt` in a bunch of dirs. A Python
script builds a bunch of `Makefile`s which use podman to do the build, and the
outputs go to the `./build` dir. The builder containers take a file name in
their entrypoint and write it to their `/outputs/` dir which is mapped to the
build dir.

This pattern is a bit convoluted and has a disk space cost, but it keeps things
isolated and will scale well in the short to medium term.

The filesystem layout looks like this:

```
qemount/
├── guests/                    # Building these gives us filesystem back-ends
│   ├── linux-6.11/            # Linux kernel 6.11 guest
│   │   ├── inputs.txt         #   it depends on these things
│   │   ├── outputs.txt        #   ... and generates these
│   │   └── Dockerfile         #   by using this Dockerfile
│   └── ...                    # todo: Haiku, AROS, Acorn, WinCE, Symbian etc
│
├── build/                     # Outputs of the build process live here
│
├── clients/                   # Building these gives us ways to talk to them
│   ├── linux-fuse/            # Linux FUSE client
│   ├── windows-driver/        # Windows client (e.g., Dokan driver)
│   └── .../                   # any and all plugins here
│
├── scripts/                   # Build scripts needed by the main makefile
│
├── testdata/                  # Source definitions, scripts & Makefile for test data
│   ├── Makefile               # Builds images into testdata/images/
│   ├── scripts/               # Helper scripts for generation/download
│   │   └── ...                # e.g., ext4.sh
│   ├── template/              # Source file structure templates
│   │   └── basic/             # A basic set of test files/dirs
│   │       ├── hello.txt
│   │       └── ...
│   └── images/                # Generated test images (gitignored)
│       ├── basic.iso9660
│       └── ...
│
├── Makefile                   # Root Makefile for orchestration
├── README.md                  # This file
└── .gitignore                 # bliss
```

## Research / notes

### Guests

#### Unices

| Filesystem      | Linux 6.11       | Linux 2.6   | FreeBSD          | NetBSD           |  Comments                       |
| --------------- | ---------------- | ----------- | ---------------- | ---------------- | ------------------------------- |
| **ext2**        | ✅               | ✅          | ✅               | ✅               | Solid everywhere                |
| **ext3**        | ✅               | ✅          | 💩               | 💩               | BSDs ignore journal             |
| **ext4**        | 🏆               | ❌          | 💩               | ❌               | Linux-only journaling           |
| **FAT12/16/32** | ✅               | ✅          | ✅               | ✅               | Universal                       |
| **exFAT**       | 🏆               | ❌          | 💩 (FUSE)        | 💩 (FUSE)        | Linux has native driver         |
| **NTFS**        | 🏆 (`ntfs3`)     | 💩 (`ntfs`) | 💩 (`ntfs`/FUSE) | 💩 (`ntfs`/FUSE) | Write support best in Linux     |
| **UFS1**        | 💩               | ❌          | ✅               | ✅               | FreeBSD best, Linux very broken |
| **ZFS**         | ✅               | ❌          | 🏆               | ✅ (module)      | All can do it, FreeBSD wins     |
| **Btrfs**       | 🏆               | ❌          | ❌               | ❌               | Linux-only, good for COW        |
| **XFS**         | 🏆               | ✅          | ❌               | ❌               | Linux-only                      |
| **F2FS**        | ✅               | ❌          | ❌               | ❌               | Android/Linux FS                |
| **JFS**         | ✅               | ✅          | ❌               | ❌               | IBM FS, Linux-only              |
| **ISO9660**     | ✅               | ✅          | 🏆               | ✅               | FreeBSD supports weird hybrids  |
| **UDF**         | ✅               | 💩          | ✅               | ✅               | CD/DVD/BR support               |
| **MinixFS**     | ✅               | ✅          | ✅ (RO)          | ✅               | Niche use                       |
| **SquashFS**    | ✅               | ❌          | ✅ (module)      | ❌               | Read-only compressed            |
| **OverlayFS**   | 🏆               | ❌          | 💩 (UnionFS)     | 💩 (Union)       | Linux OverlayFS > BSD Union     |
| **TMPFS**       | ✅               | ✅          | ✅               | ✅               | All good                        |
| **DevFS**       | ✅               | ✅          | ✅               | ✅               | Basic virtual FS                |
| **ReiserFS**    | 💩 (deprecated)  | ✅          | ❌               | ❌               | Historical only                 |
| **UFS2**        | ❌               | ❌          | 🏆               | ✅               | Only FreeBSD has full support   |
| **APFS**        | 💩 (FUSE)        | ❌          | ❌               | ❌               | Reverse engineered FUSE only    |
| **CHFS**        | ❌               | ❌          | ❌               | 🏆               | NetBSD-only, for NAND flash     |
| **LFS**         | ❌               | ❌          | ❌               | 🏆               | NetBSD log-structured           |
| **HFS**         | 💩 (HFS+)        | 💩          | ✅ (RO)          | ✅ (RO)          | Apple FS, write is weak         |


#### 💡 Unorthodox Guest ideas

| Guest    | Notes                                                             |
| -------- | ----------------------------------------------------------------- |
| WinACE   | PeaZip doesn't support ACE archives because security, but we can  |
| rsrc     | Open Windows EXE resource forks and browse icons etc inside them  |


### Hosts

#### 💡 Host ideas

There's a ton of ways we can use this

| Host           |  | Notes                                               |
| -------------- |--| --------------------------------------------------- |
| 7zip           |📦| 7zip supports plugins                               |
| PeaZip         |📦| |
| Gnome          |🪟| Gnome Desktop Virtual Filesystem                    |
| KDE            |🪟| KDE has its own VFS too                             |
| Windows Driver |🪟| |
| Web-based      |🌍| QEMU+WASM+guests = browse files on the web          |
| Python         |🤖| Python pathlib support                              |


### Project

| Feature        | Notes                                                               |
| -------------- | ------------------------------------------------------------------- | 
| Docker         | Guests as containers = free hosting + download management by Docker |
| Detection      | We can use the catalogue as a heuristic source to guess formats     |




