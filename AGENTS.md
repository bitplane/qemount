# Instructions for LLMs

## Build approach

The build system deliberately writes output artefacts into the images at podman
build time. When executed, the ENTRYPOINT of the resulting image takes a path
and copies it out of the image into the host filesystem.

This unorthodox approach is a strategic decision, we are sacrificing disk space
for reproducibility and archival. We can publish snapshot tgz of the entire OS
containing the build pipelines, all dependencies, source code and resulting
binaries, making auditable builders that will function and can be modified 50
years from now when the sources are gone and toolchains no longer work.

So stick to this pattern and don't deviate from it.

## Guest approach

QEMU creates some hardware. The `-m` flag, when passed to the runner script is
resolved inside the guest. `sh` mode gives us a debug shell for experimenting,
so the hardware config needs to be identical or we lose debugging capability.

## Branches are the enemy

Branches in general are our enemy. Programming special cases in, or any
divergences between guest conventions should be discussed first and heavily
documented. And they'll probably be refused. We simplify as we go without losing
functionality.

