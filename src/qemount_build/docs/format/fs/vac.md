---
title: VAC
related:
  - format/fs/fossil
detect:
  - offset: 0
    type: ascii
    length: 44
    value: "^vac:[0-9a-fA-F]{40}$"
---

# VAC

VAC is a Plan 9 archival filesystem whose data is stored in Venti, a
content-addressed block server. A `.vac` file is not a self-contained disk
image: it contains the root fingerprint needed to find the archive in Venti.
`vacfs` resolves that fingerprint and exposes the resulting read-only tree over
9P.

## Root reference

The textual reference consists of the prefix `vac:` followed by the 40
hexadecimal digits of a SHA-1 score:

```text
vac:64daefaecc4df4b5cb48a368b361ef56012a4f46
```

Filesystem content, directory metadata and pointer blocks live in the selected
Venti store. Consequently a useful fixture must include both the root reference
and a reproducible Venti arena; the `.vac` file alone cannot be mounted
offline.

## References

- [vac(1)](http://man.9front.org/1/vac)
- [vacfs(4)](http://man.9front.org/4/vacfs)
- [venti(8)](http://man.9front.org/8/venti)

