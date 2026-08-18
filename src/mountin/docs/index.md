---
title: Mountin
execution_env:
  MOUNTIN_CACHE_DIR: ${MOUNTIN_CACHE_DIR}
  CARGO_HOME: /host/build/cache/cargo
  CARGO_TARGET_DIR: ${MOUNTIN_CACHE_DIR}/cargo-target
  ZIG_GLOBAL_CACHE_DIR: /host/build/cache/zig/${BUILD_PLATFORM}
no_inherit:
  - provides
  - build_requires
no_merge:
  - detect
---

# Mountin Catalogue Root

Every provider instance receives a stable private build cache at
`MOUNTIN_CACHE_DIR`. The build system derives the directory from the build
platform, catalogue provider and output platform. Builders may use it for
incremental objects and other reproducible working state; they must not derive
their own provider cache paths.

Shared content-addressed caches, such as package downloads and SDK archives,
remain under `/host/build/cache` because they are intentionally reused by
several providers.

Cargo target objects use the private provider cache. Cargo downloads and Zig's
content-addressed global cache are inherited here as shared caches.
