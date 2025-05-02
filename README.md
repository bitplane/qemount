# mountq

Let's mount everything/anything using qemu, by exposing it over 9p or other
transports. Spin up a tiny VM that provides access to an image, one instance per mount.

* Have the ability to use kernel mounts in FUSE
* Run ancient Linux kernels that still had write access to now read-only filesystems
* Run old operating systems (Amiga, Acorn) with any CPU arch, and read/write their filesystems
* Make a generic driver for Windows that mounts any filesystem
* Docker image that turns any filesystem into a tar
* ... basically a clutch between any image/block device and anything else


```
mountq/
├── guest/                     # Guest environment definitions
│   ├── linux-6.11/            # Linux kernel 6.11 guest
│   │   ├── Makefile           # How to build this guest's image
│   │   ├── meta.conf          # Guest metadata (arch and FS support...)
│   │   ├── config/            # Config files for this guest, used by Makefile
│   │   │   ├── kernel.x86_64.config
│   │   │   ├── kernel.arm64.config
│   │   │   ├── busybox.x86_64.config
│   │   │   └── ...
│   │   ├── init.sh            # Template/source for init script in initramfs
│   │   └── run.sh.template    # Template for the final run.sh
│   │
│   ├── linux-5.15/            # Linux kernel 5.15 LTS guest
│   ├── linux-.../             # Variations, like out of tree modules etc
│   ├── freedos/               # FreeDOS guest (Makefile might wrap different tools)
│   └── ...                    # Haiku, Amiga, Mac, Acorn, WinCE etc
│
├── build/                     # Build output (gitignored)
│   ├── images/                # Built VM images
│   │   ├── linux-6.11-x86_64/ # Specific built image
│   │   │   ├── meta.conf      # Copy of metadata for this build
│   │   │   ├── bzImage        # Kernel (or Image.gz for arm64, etc.)
│   │   │   ├── initramfs.cpio.gz # Initramfs (with export logic)
│   │   │   └── run.sh         # Generated script to launch this VM image
│   │   ├── linux-6.11-arm64/
│   │   ├── freedos-x86_64/
│   │   └── haiku-x86_64/
│   │
│   ├── cache/                 # Cached downloads, extracted src etc
│   │   ├── linux-6.11.tar.xz
│   │   └── busybox-1.36.1.tar.bz2
│   │
│   └── registry.json          # Generated registry of all built images
│
├── clients/                   # Client implementations (for host OSes)
│   ├── linux-fuse/            # Main reason for the project to exist
│   ├── windows-driver/
│   ├── mac/
│   └── .../                   # file-roller, docker web, anything at all!
│
├── scripts/                   # Helper scripts (called by Makefiles or for users)
│   ├── build-registry.sh      # Script to generate registry.json from build/images
│   ├── find-vm.sh             # Script to find VM in registry by capabilities
│   └── setup-deps.sh          # (Optional: Install host build dependencies)
│
├── Makefile                   # Root Makefile for orchestration
└── README.md                  # Docs
```
