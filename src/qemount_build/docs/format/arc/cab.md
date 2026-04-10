---
title: CAB
created: 1996
detect:
  - offset: 0
    type: string
    value: "MSCF"
---

# CAB (Microsoft Cabinet)

Microsoft Cabinet format was introduced in 1996 for software distribution
on Windows. Used for Windows Installer packages, driver distribution,
Windows Update, and Internet Explorer downloads.

## Characteristics

- MSZIP, LZX, or Quantum compression
- Multi-cabinet spanning (large installs across multiple files)
- Folder-based compression (files grouped for better ratios)
- Digital signatures
- Maximum 65,535 files per cabinet

## Structure

```
Cabinet header (36 bytes):
  Offset  Size  Field
  0       4     Signature ("MSCF" = 4D 53 43 46)
  4       4     Reserved (0)
  8       4     Cabinet size
  12      4     Reserved (0)
  16      4     Offset to first file entry
  20      4     Reserved (0)
  24      1     Minor version
  25      1     Major version (3)
  26      2     Number of folders
  28      2     Number of files
  30      2     Flags
  32      2     Set ID
  34      2     Cabinet index in set
```

## Compression Methods

| ID | Method  | Notes |
|----|---------|-------|
| 0  | None    | Stored |
| 1  | MSZIP   | Deflate variant |
| 2  | Quantum | Proprietary |
| 3  | LZX     | Best ratio, used for Windows installs |
