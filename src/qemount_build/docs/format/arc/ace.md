---
title: ACE
created: 1998
discontinued: 2007
detect:
  - offset: 7
    type: string
    value: "**ACE**"
---

# ACE (WinACE)

ACE was created by Marcel Lemke (e-merge GmbH, Germany) around 1998 as a
competitor to RAR and ZIP, claiming better compression ratios. WinACE was
the primary tool for creating and extracting ACE archives. The last release
was WinACE 2.69 (~2007), after which the developer disappeared and the
format was abandoned.

## Characteristics

- LZ77 + Huffman compression
- Solid archive mode
- Multi-volume spanning
- Recovery records
- Dictionary sizes up to 4MB (ACE 2.0)
- Encryption support
- Proprietary, closed-source compression algorithm

## Structure

```
Archive header:
  Offset  Size  Field
  0       2     CRC16 of header (from byte 4)
  2       2     Header size (LE)
  4       1     Header type (0x00 = main header)
  5       2     Flags (LE)
  7       7     Magic ("**ACE**")
  14      1     Version needed to extract
  15      1     Creator version
  16      1     Host OS (0=DOS, 1=OS/2, 2=Win32, 3=Unix, 4=Mac)
  17      1     Volume number
  18      4     Creation timestamp (MS-DOS format)
```

File entry headers follow with type 0x01, containing compressed/original
sizes, CRC32, compression parameters, and variable-length filename.

## Security — CVE-2018-20250

In 2019, Check Point Research disclosed a path traversal vulnerability in
`unacev2.dll`, the closed-source library used by WinRAR and others to
extract ACE files. The DLL had not been updated since 2006 and no source
code was available. An attacker could craft an ACE file that extracted to
arbitrary paths (e.g. the Windows Startup folder). WinRAR responded by
dropping ACE support entirely in v5.70, affecting ~500 million users.

## Current Status

- Format is dead — no maintained creation tools
- `acefile` (Python) can read/extract ACE 1.0 and 2.0 archives
- `unace` command-line extractor exists (legal status unclear)
- Compression algorithm never published — only decompression reverse-engineered
- WinRAR, 7-Zip, and other major archivers have all dropped ACE support

## References

- [acefile on PyPI](https://pypi.org/project/acefile/) — Python ACE reader
- [Check Point CVE-2018-20250](https://research.checkpoint.com/2019/extracting-code-execution-from-winrar/)
