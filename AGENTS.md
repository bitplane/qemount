# Instructions for LLMs

## Vision

qemount mounts anything. Disk images, archives, filesystems from dead operating
systems - if it ever existed, qemount should be able to open it.

The approach: spin up tiny VMs (guests) that use real kernels to read formats,
expose the contents over 9P protocol to the host. Linux 6.17 for modern formats,
Linux 2.6 for legacy (ReiserFS, etc.), NetBSD for UFS/ZFS, eventually esoteric
kernels for truly obscure formats.

## Philosophy

**Pure over pragmatic.** We get things right rather than get things done. This
project aims to be technically excellent - a showcase of what careful engineering
looks like, not typical "make it work" LLM-assisted code.

**Branches are the enemy.** Special cases, divergent code paths, workarounds -
these are technical debt. If something needs a special case, the abstraction is
wrong. We simplify continuously without losing functionality.

**Declarative source of truth.** The markdown frontmatter defines everything:
build dependencies, format detection rules, documentation, the website. One
source, many outputs.

**No root required.** Neither at build time nor runtime. All build dependencies
are isolated in containers (podman). The final tools run unprivileged.

**Weed the garden.** Continuous refinement. When something becomes inconsistent
or awkward, fix it immediately rather than accumulating cruft.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Frontend Clients                          │
│  FUSE, GVFS, KIO, 7zip plugin, PeaZip, WASM, Windows driver...  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                         libqemount                               │
│  - Recursive format detection (disk → partition → fs → archive) │
│  - Guest selection (best kernel for format + host arch)         │
│  - Transport orchestration (9P, future: NFS, etc.)              │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                          Guests                                  │
│  Linux 6.17 │ Linux 2.6 │ NetBSD 10 │ (future: AROS, Haiku...)  │
│  Minimal VMs with busybox + 9P server, run via QEMU             │
└─────────────────────────────────────────────────────────────────┘
```

libqemount is the brain. Clients ask it to "mount this and give me a transport
endpoint". It detects the format, picks the right guest, starts QEMU, returns
a socket. The client connects and does I/O.

## Build System

The Python package `qemount_build` orchestrates everything via podman containers.

### Concepts

**Catalogue**: All `*.md` files in `src/qemount_build/` are parsed. YAML
frontmatter defines build metadata, markdown body becomes documentation.

**Paths**: File paths map to logical catalogue paths. `bin/linux/busybox/index.md`
becomes catalogue path `bin/linux/busybox`. Metadata inherits down the tree.

**provides/requires**: Each path can `provide` outputs and `require` inputs.
The build system resolves the dependency graph and builds in order.

```yaml
---
title: BusyBox
requires:
  - sources/busybox-1.36.1.tar.bz2
provides:
  - bin/${ARCH}-linux-${ENV}/busybox
---
```

**env inheritance**: Environment variables defined in parent `index.md` files
cascade to children. Variables use `${VAR}` syntax.

**docker: prefix**: `provides: docker:builder/compiler/rust` means the target
builds a container image. `requires: docker:...` means it needs that image.

### Commands

```bash
# Show what can be built
python -m qemount_build outputs

# Show dependency graph for a target
python -m qemount_build deps bin/x86_64-linux-musl/busybox

# Build a target (and all dependencies)
python -m qemount_build build bin/x86_64-linux-musl/busybox
```

### Build flow

1. Dockerfile in the path's directory → build container image
2. If `provides` includes files → run container with `/host/build` mounted
3. Container writes outputs to `/host/build/<provides-path>`
4. Build system verifies outputs exist

## Directory Structure

```
src/qemount_build/          # Python package (the build system)
├── bin/                    # Binary build definitions
│   ├── detect/             # Format detection CLI tool
│   ├── linux/              # Linux-hosted binaries (busybox, etc.)
│   ├── netbsd/             # NetBSD-hosted binaries
│   └── qemu/               # Guest VM builds
│       ├── linux/          # Linux guests (2.6, 6.17)
│       └── netbsd/         # NetBSD guests
├── builder/                # Build infrastructure (compilers, disk tools)
├── data/                   # Test data generation (filesystem images)
├── docs/                   # Documentation (also defines formats)
│   └── format/             # Format detection rules live here
│       ├── fs/             # Filesystems (ext4, ntfs, etc.)
│       ├── pt/             # Partition tables
│       ├── arc/            # Archives (tar, zip, etc.)
│       └── disk/           # Disk image formats (qcow2, vdi, etc.)
├── lib/                    # Library builds
│   ├── format/             # Compiles detection rules → msgpack
│   └── qemount/            # Rust library (libqemount)
├── sources/                # Source tarball definitions
├── catalogue.py            # Loads markdown → catalogue dict
├── runner.py               # Executes builds via podman
└── main.py                 # CLI entry point

build/                      # Build outputs (gitignored)
├── bin/                    # Compiled binaries by target triple
├── lib/                    # Compiled libraries by target triple
├── data/                   # Generated test filesystem images
├── sources/                # Downloaded source tarballs
└── catalogue.json          # Compiled catalogue snapshot

tests/                      # pytest tests
scripts/                    # Development scripts (venv, coverage, etc.)
```

## Format Detection

Detection rules are defined in `docs/format/` frontmatter:

```yaml
---
title: ext4
detect:
  - offset: 0x438
    type: le16
    value: 0xef53
    then:
      - offset: 0x45c
        type: le32
        mask: 0x40
        op: "&"
        value: 0x40
---
```

The `lib/format/compile.py` script reads these from the catalogue and generates
`build/lib/format.bin` (msgpack). The Rust library embeds this at compile time.

Detection is recursive: detect disk image format → detect partition table →
detect filesystem → detect archive inside → etc.

## Target Naming

Paths follow Rust target triple order: `{arch}-{os}[-{env}]`

Examples:
- `bin/x86_64-linux-musl/busybox` - Linux static binary
- `bin/x86_64-linux-gnu/detect` - Linux dynamic binary
- `bin/x86_64-netbsd/simple9p` - NetBSD (no env suffix)
- `lib/x86_64-darwin/libqemount.dylib` - macOS
- `lib/x86_64-windows/qemount.dll` - Windows

**Environment variables:**
- `ARCH` - Target architecture (x86_64, aarch64)
- `HOST_ARCH` - Host machine architecture
- `ENV` - libc environment (musl, gnu) - only for Linux

**ARCH vs HOST_ARCH:** Some builders can't cross-compile, so they use `HOST_ARCH`
to indicate "we can only build for the architecture we're running on". This is a
builder limitation, not a statement about where the binary runs. Both produce the
same type of output (e.g., static musl binaries), the variable just reflects
cross-compilation capability.

## Current State

Early scaffolding. What works:
- Build system resolves dependencies and builds in containers
- Linux 2.6 and 6.17 guests boot, mount filesystems, serve 9P
- NetBSD 10 guest builds (needs manual 9P init)
- Format detection library compiles rules and detects ~40 formats
- 9pfuse client connects and mounts

What's next:
- libqemount: guest selection and orchestration (not just detection)
- Consistent target naming
- Build caching (hash inputs to skip unchanged targets)
- More formats, more guests
- Frontend clients (FUSE wrapper, then plugins, then everything else)

## Guest Conventions

QEMU creates hardware. The `-m` flag passed to the runner script selects what
runs inside the guest. `sh` gives a debug shell, `9p` starts the 9P server.

Hardware config must be identical between modes or debugging becomes impossible.
This is why we resist special cases - debug and production paths must match.

## Testing

```bash
make test      # Run pytest
make coverage  # Generate coverage report
```

Tests are functional (pytest style, not unittest classes). Mocks indicate
poor isolation - fix the code instead.
