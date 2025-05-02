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
├── src/
│   └── os/                   # OS definitions
│       ├── linux-6.11/       # Linux kernel 6.11
│       │   ├── build.sh      # How to build this OS
│       │   └── meta.conf     # OS metadata including arch and FS support
│       ├── linux-5.15/       # Linux kernel 5.15 LTS
│       ├── freedos/          # FreeDOS
│       └── haiku/            # Haiku OS
│
├── build/                    # Build output
│   ├── images/               # Built VM images
│   │   ├── linux-6.11-x86_64/
│   │   │   ├── meta.conf     # Complete metadata
│   │   │   ├── bzImage       # Kernel image
│   │   │   ├── initramfs.cpio.gz  # Initial RAM disk
│   │   │   ├── run.sh        # Run script
│   │   │   └── fs/           # Filesystem capabilities
│   │   │       ├── iso9660   # ISO9660 capabilities
│   │   │       ├── ext4      # ext4 capabilities
│   │   │       └── ntfs      # NTFS capabilities
│   │   │
│   │   ├── linux-6.11-arm64/
│   │   ├── freedos-x86_64/
│   │   └── haiku-x86_64/
│   │
│   └── registry.json         # Generated registry
│
├── clients/                  # Client implementations
│   ├── linux/
│   ├── windows/
│   ├── macos/
│   └── wasm/
│
├── scripts/
│   ├── build-image.sh        # Build a specific image
│   ├── build-all.sh          # Build all images
│   ├── build-registry.sh     # Generate registry
│   └── find-vm.sh            # Find VM in registry
│
├── build.sh                  # Main build script
└── README.md

```


