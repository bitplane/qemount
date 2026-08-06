---
title: 9front 95ad97b9
version: 95ad97b98af078a1ca6a45f76725f6b693fa6795
urls:
  - git-full+git://git.9front.org/plan9front/9front#95ad97b98af078a1ca6a45f76725f6b693fa6795
provides:
  - sources/9front-95ad97b98af078a1ca6a45f76725f6b693fa6795.tar.gz
---

# 9front

The 9front source tree used by the initial qemount build proof, pinned to the
commit used for official build 11957. The upstream Git server does not support
shallow clients, so the downloader fetches the complete repository and exports
only the selected worktree.
