# qemount

Let's mount everything/anything using qemu, by exposing it over 9p or other
transport. Spin up a tiny VM that provides access to an image, one instance per mount.

* Have the ability to use kernel mounts in FUSE
* Run ancient Linux kernels that still had write access to now read-only filesystems
* Run old operating systems (Amiga, Acorn) with any CPU arch, and read/write their
  filesystems
* Make a generic driver for Windows that mounts any filesystem
* Docker image that turns any filesystem into a tar
* ... basically a clutch between any image/block device, URL, file and anything else,
  the UNIX way - everything is a file.


## Project Structure
```
qemount/
├── guests/                    # Building these gives us filesystem back-ends
│   ├── linux-6.11/            # Linux kernel 6.11 guest
│   │   ├── inputs.txt         #   it depends on these things
│   │   ├── outputs.txt        #   ... and generates these
│   │   └── Dockerfile         #   by using this Dockerfile
│   └── ...                    # Haiku, Amiga, Mac, Acorn, WinCE etc
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

## Support

### Linux / BSD

| Filesystem      | Linux 6.11       | Linux 2.6   | FreeBSD          | NetBSD           |  Comments                       |
| --------------- | ---------------- | ----------- | ---------------- | ---------------- | ------------------------------- |
| **ext2**        | ✅               | ✅          | ✅               | ✅               | Solid everywhere                |
| **ext3**        | ✅               | ✅          | 💩               | 💩               | BSDs ignore journal             |
| **ext4**        | 🏆               | ❌          | 💩               | ❌               | Linux-only journaling           |
| **FAT12/16/32** | ✅               | ✅          | ✅               | ✅               | Universal                       |
| **exFAT**       | 🏆               | ❌          | 💩 (FUSE)        | 💩 (FUSE)        | Linux has native driver         |
| **NTFS**        | 🏆 (`ntfs3`)     | 💩 (`ntfs`) | 💩 (`ntfs`/FUSE) | 💩 (`ntfs`/FUSE) | Write support best in Linux     |
| **UFS1**        | 💩               | ❌          | ✅               | ✅               | FreeBSD best, Linux very broken |
| **UFS2**        | ❌               | ❌          | 🏆               | ✅               | Only FreeBSD has full support   |
| **ZFS**         | ✅               | ❌          | 🏆               | ✅ (module)      | All can do it, FreeBSD wins     |
| **Btrfs**       | 🏆               | ❌          | ❌               | ❌               | Linux-only, good for COW        |
| **XFS**         | 🏆               | ✅          | ❌               | ❌               | Linux-only                      |
| **ReiserFS**    | 💩 (deprecated)  | ✅          | ❌               | ❌               | Historical only                 |
| **F2FS**        | ✅               | ❌          | ❌               | ❌               | Android/Linux FS                |
| **JFS**         | ✅               | ✅          | ❌               | ❌               | IBM FS, Linux-only              |
| **ISO9660**     | ✅               | ✅          | 🏆               | ✅               | FreeBSD supports weird hybrids  |
| **UDF**         | ✅               | 💩          | ✅               | ✅               | CD/DVD/BR support               |
| **HFS**         | 💩 (HFS+)        | 💩          | ✅ (RO)          | ✅ (RO)          | Apple FS, write is weak         |
| **APFS**        | 💩 (FUSE)        | ❌          | ❌               | ❌               | Reverse engineered FUSE only    |
| **CHFS**        | ❌               | ❌          | ❌               | 🏆               | NetBSD-only, for NAND flash     |
| **LFS**         | ❌               | ❌          | ❌               | 🏆               | NetBSD log-structured           |
| **MinixFS**     | ✅               | ✅          | ✅ (RO)          | ✅               | Niche use                       |
| **SquashFS**    | ✅               | ❌          | ✅ (module)      | ❌               | Read-only compressed            |
| **OverlayFS**   | 🏆               | ❌          | 💩 (UnionFS)     | 💩 (Union)       | Linux OverlayFS > BSD Union     |
| **TMPFS**       | ✅               | ✅          | ✅               | ✅               | All good                        |
| **DevFS**       | ✅               | ✅          | ✅               | ✅               | Basic virtual FS                |
| **ProcFS**      | ✅               | ✅          | ✅               | ✅               | Universally supported           |

