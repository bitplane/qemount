---
title: Binaries
arch:
  - ${ARCH}
env:
  HOST_ARCH: ${HOST_ARCH}
  ARCH: ${ARCH}
  SELF: ${SELF}
  JOBS: ${JOBS}
---

# Binaries

Buildable artefacts. Outputs go to `build/` directory.

Default architecture is native (`${ARCH}` = build host). Children can override
with specific architectures or exclude with `-arch`.

Child-types of these are organized by platform.
