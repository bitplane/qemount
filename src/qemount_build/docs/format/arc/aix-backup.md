---
title: AIX Backup/Restore
created: 1986
related:
  - format/arc/tar
  - format/arc/cpio
detect:
  any:
    - offset: 0
      type: be32
      value: 0x09006bea
    - offset: 0
      type: be32
      value: 0x09006fea
---

# AIX Backup/Restore Format (BFF)

The Backup-file Format (BFF) is the native archive format used by IBM AIX,
created using the `backup` command and read with `restore`. It stores files
in a manner analogous to tar. BFF is also the format used for AIX software
packages installed via `installp`.

## Characteristics

- Sequential file archive (like tar)
- Used for both system backups and software distribution
- No standard file extension (`.bff` is common for packages)
- Big-endian (AIX runs on POWER/PowerPC)

## Detection

Two magic numbers at offset 0 (big-endian uint32):

| Magic | Hex |
|-------|-----|
| `0x09006bea` | Standard BFF |
| `0x09006fea` | Alternate BFF |

Both are recognised by `file(1)` as "AIX backup/restore format file"
(magic database: `Magdir/ibm6000`).

## Usage

```sh
# Create a backup
backup -i -f /dev/rmt0       # backup to tape
backup -i -f archive.bff     # backup to file

# Restore
restore -x -f archive.bff    # extract

# Install software package
installp -a -d package.bff all
```

## Common File Extensions

| Extension | Usage |
|-----------|-------|
| `.bff` | Software packages (installp) |
| `.bck` | Backup files |
| `.img` | Installation media images |
| (none) | Raw backup streams |

## References

- [Wikipedia: Backup-file Format](https://en.wikipedia.org/wiki/Backup-file_Format)
