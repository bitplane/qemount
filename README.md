# 🔌 mountin

Mount anything by giving the image or data file to an operating system that
understands it or has native tools for it, then exposing the result over 9P.
mountin runs one small guest per image, using real kernels and filesystem
implementations instead of reimplementing every format on the host. In future,
it'll support archive formats and obscure data files too.

## ✅ STATUS

⚠️  unstable / pre-alpha / experimental ⚠️

## 🛑 STOP! 🛑

**MAKE BACKUPS OF YOUR DISK IMAGES BEFORE USING THIS TOOL**

Currently, there's:

* guests for Linux 2.6, Linux 6.12, NetBSD 10.0, Dragonfly BSD, PureDarwin,
  AROS and Haiku. Architecture coverage varies depending on build host.
* 9P2000.U support via a [9p server](https://github.com/bitplane/simple9p) an
  9pfuse client.
* A huge collection of test data fixtures, with many custom mkfs and archive and
  compression tools.
* A Python-based, podman-isolated build system that runs rootless and dodges
  dependency hell.
* A Rust library to detect and extract filesystems from many image formats.
* Full archival backup sources, outputs and containers used to build everything,
  saved on archive.org for future historians. 

### Building

Install: 

* `podman`, `make`, `python3` (+ venv + pip) to build.
* `fuse` to mount images with the 9p client.
* `xz` if you want to archive the lot.

Everything else is installed in containers, use the `mountin` module or
script to build stuff. It might take a while.

```sh
# install
make dev
source .venv/bin/activate

# list targets
mountin-build outputs

# pick one and build it
mountin-build build bin/qemu/x86_64-linux/6.12/boot/rootfs.img

# inspect or explicitly request cross-platform outputs
mountin-build outputs --output-arch i386
mountin-build outputs --output-platform x86_64-windows-gnu
mountin-build outputs --all-platforms

# record the catalogue artefacts currently present
mountin-build inventory

make help   # for a full list of targets.
# make      # build everything for this arch
# make all  # to build everything possible. might take a while.
```

Guest and transport selection, detection engine and launch layer are still
under construction, see the [todo list](src/mountin/docs/todo.md). There's
`./scripts` for data recovery though.

Catalogue and format encyclopedia can be found is in the `src/mountin/`
tree - there's no html builder yet.

## Format support

Guest operating systems are the smallest builds I could get running while
preserving broad support. Every entry below has been tested end to end; `(ro)`
means read-only. Absence from a guest row is not proof of incompatibility.
YMMV, expect occasional regressions.

| Guest | Partition tables and disk layouts | Filesystems |
| ----- | --------------------------------- | ----------- |
| **Linux 6.12** | MBR/DOS, GPT, BSD disklabel, Apple APM, Amiga RDB, Atari AHDI, Sun SPARC VTOC8, SGI DVH, LDM, Minix, UBI, Acorn, AIX, Ultrix, SYSV68, Rio Karma, OSF/1, HP-UX LIF, QNX4 PT, Plan 9, NetWare, Hybrid MBR, Protective MBR, OpenBSD, DragonFly, CP/M-86 | ext2/3/4, FAT12/16/32, exFAT, NTFS (`ntfs3`), ISO9660, UDF, HFS/HFS+, XFS, JFS, Btrfs, F2FS, bcachefs, EROFS, ReiserFS, Amiga OFS/FFS, Minix, V7, SysV, SquashFS, CramFS, RomFS, EFS, BeFS, HPFS, QNX4/6, ADFS, VxFS, OMFS, NILFS2, GFS2, BFS, JFFS2, UBIFS, High Sierra |
| **Linux 2.6** | MBR/DOS, GPT, BSD disklabel, Apple APM, Amiga RDB, Atari AHDI, Sun SPARC VTOC8, SGI DVH, Minix, UBI, Acorn, AIX, Ultrix, SYSV68, OSF/1, HP-UX LIF, QNX4 PT, Plan 9, NetWare, Hybrid MBR, Protective MBR, OpenBSD, CP/M-86 | ext2/3/4, FAT12/16/32, ISO9660, UDF, HFS/HFS+, XFS, JFS, Btrfs, ReiserFS, Amiga OFS/FFS, Minix, V7, SquashFS, CramFS, RomFS, EFS, BeFS, HPFS, QNX4, ADFS, VxFS, OMFS, NILFS2, GFS2, OCFS2, BFS, JFFS2, High Sierra |
| **NetBSD 10** | MBR/DOS, GPT, BSD disklabel, Apple APM, Amiga RDB, Atari AHDI, Hybrid MBR, Protective MBR | ext2/3 (ext3 via ext2), FAT12/16/32, ISO9660, UDF, HFS+, UFS/FFS, LFS, V7, EFS, Filecore |
| **DragonFly 6.4** | MBR/DOS, GPT, BSD disklabel, Hybrid MBR, Protective MBR | ext2/3 (ext3 via ext2), FAT12/16/32, ISO9660, UDF (ro), UFS1, HAMMER/HAMMER2 |
| **AROS i386** | MBR/DOS, GPT, Amiga RDB, Protective MBR | FAT12/16/32, ISO9660, Amiga OFS/FFS, SFS, PFS |
| **Haiku x86_64** | MBR/DOS, GPT, Hybrid MBR, Protective MBR | ext2/3/4, FAT12/16/32, exFAT (ro), NTFS, ISO9660, UDF (ro), Btrfs (ro), ReiserFS (ro), BeFS |
| **PureDarwin 17.4** | MBR/DOS, GPT, Apple APM, Protective MBR | HFS/HFS+/HFSX |
| **9front** | MBR/DOS, Plan 9 | FAT12/16/32, ISO9660 (no Rock Ridge symlinks), PAQFS (ro), FlashFS, HJFS, GEFS, CWFS, V5/V6 (ro), UNIX/32V (ro), V10 (ro) |
| **illumos x86_64** | MBR/DOS, GPT, Solaris x86 VTOC16 (inside MBR) | FAT12/16/32, ISO9660, UFS1 |

### Known bad results

These combinations have been tested but are not counted as support:

- **Linux 6.12:** UFS/FFS support is limited.
- **Linux 2.6:** NTFS (`ntfs`), UFS/FFS, and SysV; SysV symlinks can crash the guest.
- **NetBSD 10:** NTFS (`ntfs`) and Amiga OFS/FFS (`adosfs`).
- **DragonFly 6.4:** NTFS directory reads can panic the guest.

### Tracked gaps

These formats were present in the old matrices but do not yet have a working
guest:

- **Partition tables and disk layouts:** IBM DASD (S/390), PC-98, and NeXT.
- **Filesystems:** SACFS (the reader uses obsolete 9P1), Coda, ZFS, APFS, and ReFS.
