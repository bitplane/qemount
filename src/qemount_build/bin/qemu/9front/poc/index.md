---
title: 9front source-build proof
env:
  BUILDER: builder/compiler/9front
requires:
  - docker:${BUILDER}
---

# 9front source-build proof

Initial amd64 source-build and boot proof. Runtime integration and appliance
reduction are intentionally outside this target.
