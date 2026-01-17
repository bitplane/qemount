---
title: Format detection rules
provides:
  - lib/format.bin
---

# Format detection rules

Compiles detection rules from the catalogue into a msgpack binary
for consumption by the Rust detection library.

Reads `format/*` paths from `catalogue.json` and extracts their
`detect:` metadata into a normalized structure.
