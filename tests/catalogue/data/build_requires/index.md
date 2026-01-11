---
requires:
  - existing/dep
build_requires:
  - sources/foo
  - sources/bar
provides:
  - docker:my/image
---

# Test build_requires

Test that build_requires is merged into requires.
