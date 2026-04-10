---
title: StegFS
created: 1999
related:
  - format/fs/ext2
---

# StegFS (Steganographic File System)

StegFS is a steganographic filesystem for Linux, designed to provide
plausible deniability for encrypted files. Unlike conventional encrypted
filesystems where the existence of encrypted data is obvious, StegFS hides
files within random-looking data so that an attacker cannot prove files exist
without the correct passphrase.

Originally developed by Andrew D. McDonald and Markus G. Kuhn at the
University of Cambridge (1999), based on ext2. A later FUSE-based
reimplementation by albinoloverats stores data in a file that appears to
contain random noise.

## Characteristics

- Plausible deniability — encrypted data indistinguishable from random
- Multiple security levels with separate passphrases
- Based on ext2 (original) or standalone random block device (FUSE version)
- Files can be overwritten by other security levels unknowingly
- No file listing without correct passphrase
- Capacity decreases as more security levels are used

## Detection

StegFS intentionally has no magic number, signature, or identifiable
structure. The entire volume appears as random data. This is by design —
if the filesystem were detectable, it would defeat the purpose of
steganographic storage.

In "paranoid mode" (FUSE version), the application cannot even confirm it
is mounting an actual StegFS partition; it ignores basic sanity checks and
attempts to decrypt with the provided passphrase.

This means StegFS cannot be detected by qemount or any other format
identification tool — which is exactly the point.

## Implementations

| Version | Base | Author | Year |
|---------|------|--------|------|
| 1.x | ext2 kernel module | McDonald & Kuhn | 1999 |
| 2.x | FUSE, standalone | albinoloverats | 2010+ |

## Guest Support

The original kernel module worked with Linux 2.2-2.4. The FUSE version
works on any Linux with FUSE support. Neither is in mainline Linux.
