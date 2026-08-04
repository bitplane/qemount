---
title: DragonFly BSD 6.4.2
env:
  BUILDER: builder/compiler/dragonfly/6.4.2/x86_64
requires:
  - docker:${BUILDER}
---

# DragonFly BSD 6.4.2

The initial guest is a full live system used to establish filesystem and
partition-table compatibility before reducing it to an appliance.
