---
title: Test Data
---

# Test Data Builders

Builders that create test images for various formats. Each builder produces
a small, valid image containing test files that can be used to verify qemount
can correctly read the format.

## Structure

- `data/fs/` - Filesystem image builders
- `data/arc/` - Archive builders
- `data/disk/` - Disk/volume image builders
- `data/templates/` - Source files used by builders
