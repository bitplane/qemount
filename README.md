# 🔌 qemount

Let's mount everything/anything using qemu, by exposing it over 9p. Spin up a
tiny VM that provides access to an image, one instance per mount.

* Have the ability to use kernel mounts in FUSE
* Proxy ancient systems with native support for crusty old filesystems
* ... basically a clutch between any image/block device, URL, file and anything
  else, the UNIX way - everything is a file.

## ✅ STATUS

0: unstable / pre-alpha

## ⚙️ Usage

Currently there's:

* no filesystem catalogue
* no safety settings, everything is read/write even if it'll destroy disks
* no client library for cross platform access
* no packaging / install scripts

But there is:

* A FUSE client
* Linux 2.6, Linux 6.17 and NetBSD 10.0 guests

To use it:

1. Install `podman`, `fuse`, `make` and `qemu`
2. Type `make` to build the guests.
3. Use `./build/run-qemu.sh` to start one of the guests with `-i some-image`
   and `-m 9p` to run the 9p init script.
4. Once it's started and is grumbling about not having a connection (not
   before), connect to it with the 9p FUSE client using:
   `build/clients/linux-fuse/x86_64/bin/9pfuse /tmp/9p.sock /some/mount/point`

If the stars align, you'll be able to mangle the files in your given disk image.

### 🗺️ Plan

#### 1. Flesh it out

- [x] more guests
  - [x] Linux 2.6
  - [ ] NetBSD 10

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

- [ ] build and install scripts
  - [ ] write an installer
  - [ ] xdg launcher
- [ ] safety
  - [ ] mount read only by default
  - [ ] make a test framework
    - [x] data builder system (18 formats)
    - [ ] test runner
- [ ] fix bugs
  - [ ] simple9p
    - [ ] spam in file browser
  - [ ] FUSE
    - [ ] block size wrong for `du`

#### 4. Embrace, Extend, Exaggerate 

- [ ] add more guests
  - [ ] AROS
  - [ ] Haiku
  - [ ] Atari ST (STEEM?)

## 🪓 Hacking

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
│   ├── linux/                 # Linux guests
│   │   ├── bin/               #   Shared binaries (busybox, socat, simple9p)
│   │   ├── initramfs/         #   Shared initramfs builder
│   │   ├── 6.17/              #   Linux kernel 6.17 guest
│   │   └── 2.6/               #   Linux kernel 2.6 guest (legacy filesystems)
│   └── ...                    # todo: Haiku, AROS etc
│
├── common/                    # Shared build infrastructure
│   ├── compiler/              # Compiler images (linux/2, linux/6, haiku)
│   ├── run/                   # Runtime scripts (qemu launcher)
│   └── scripts/               # Build system scripts
│
├── clients/                   # Building these gives us ways to talk to guests
│   └── linux-fuse/            # Linux FUSE 9p client
│
├── tests/                     # Test infrastructure
│   └── data/
│       ├── templates/         # Source file templates for test images
│       ├── fs/                # Per-filesystem image builders
│       └── images/            # Generated test images (in build/)
│
├── build/                     # Outputs of the build process
│
├── Makefile                   # Root Makefile for orchestration
├── README.md                  # This file
└── .gitignore                 # bliss
```

## 📔 Notes

### Guests

#### Unices (to move to catalogue)

| Filesystem      | Linux 6.17       | Linux 2.6   | FreeBSD          | NetBSD           |  Comments                       |
| --------------- | ---------------- | ----------- | ---------------- | ---------------- | ------------------------------- |
| **ext2**        | ✅               | ✅          | ✅               | ✅               | Solid everywhere                |
| **ext3**        | ✅               | ✅          | 💩               | 💩               | BSDs ignore journal             |
| **ext4**        | 🏆               | 💩          | 💩               | ❌               | Linux-only journaling           |
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
| **ReiserFS**    | ❌ (removed 6.13)| ✅          | ❌               | ❌               | Historical only                 |
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
| PeaZip         |📦|                                                     |
| Gnome          |🪟| Gnome Desktop Virtual Filesystem                    |
| KDE            |🪟| KDE has its own VFS too                             |
| Windows Driver |🪟|                                                     |
| Web-based      |🌍| QEMU+WASM+guests = browse files on the web          |
| Python         |🤖| Python pathlib support                              |
| Node           |🤖| | 

### More catalogue stuff

We can mine these for detection rules

* `file`     - detects lots of filesystems
* `disktype` - better detection for more types and
  [samples](https://github.com/kamwoods/disktype/tree/master/misc/file-system-sampler)
* `amitools` - Amiga filesystems

