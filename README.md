# qemount

Let's mount everything/anything using qemu, by exposing it over 9p or other
transports. Spin up a tiny VM that provides access to an image, one instance per mount.

* Have the ability to use kernel mounts in FUSE
* Run ancient Linux kernels that still had write access to now read-only filesystems
* Run old operating systems (Amiga, Acorn) with any CPU arch, and read/write their filesystems
* Make a generic driver for Windows that mounts any filesystem
* Docker image that turns any filesystem into a tar
* ... basically a clutch between any image/block device and anything else


## Project Structure (out of date - now using containers)
```
qemount/
├── guest/                     # Guest environment definitions
│   ├── linux-6.11/            # Linux kernel 6.11 guest
│   │   ├── Makefile           # How to build this guest's image
│   │   ├── meta.conf          # Guest metadata (arch, FS support, protocols, etc.)
│   │   ├── config/            # Config files for this guest (kernel, busybox...)
│   │   │   ├── kernel.x86_64.config
│   │   │   ├── kernel.arm64.config
│   │   │   └── ...
│   │   ├── init.sh            # Template/source for init script in initramfs (Linux)
│   │   └── run.sh.template    # Template for the final run.sh launcher
│   │
│   ├── linux-5.15/            # Linux kernel 5.15 LTS guest
│   │   └── ... (Makefile, meta.conf, etc.)
│   ├── linux-.../             # Variations, like out of tree modules etc
│   ├── freedos/               # FreeDOS guest (Makefile might wrap different tools)
│   │   └── ...
│   └── ...                    # Haiku, Amiga, Mac, Acorn, WinCE etc
│
├── build/                     # Build output for VM images & cache (gitignored)
│   ├── images/                # Built VM images
│   │   ├── linux-6.11-x86_64/ # Specific built image instance
│   │   │   ├── meta.conf      # Copy of metadata for this build
│   │   │   ├── bzImage        # Kernel (or Image.gz for arm64, etc.)
│   │   │   ├── initramfs.cpio.gz # Initramfs (with export logic)
│   │   │   └── run.sh         # Generated script to launch this VM image
│   │   ├── linux-6.11-arm64/
│   │   └── ...
│   ├── cache/                 # Cached downloads (tarballs etc.)
│   │   └── ...
│   └── registry.json          # Generated registry of all built VM images
│
├── clients/                   # Client implementations (for host OSes)
│   ├── linux-fuse/            # Linux FUSE client
│   ├── windows-driver/        # Windows client (e.g., Dokan driver)
│   ├── mac/                   # macOS client (e.g., macFUSE)
│   └── .../                   # file-roller, docker web, anything at all!
│
├── scripts/                   # Helper scripts (called by Makefiles or for users)
│   ├── build-registry.sh      # Script to generate registry.json from build/images/
│   ├── find-vm.sh             # Script to find VM in registry by capabilities
│   └── setup-deps.sh          # (Optional: Install host build dependencies)
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
└── .gitignore                 # Should ignore /build/ and /testdata/images/
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

