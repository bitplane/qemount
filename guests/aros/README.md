# AROS Guest

Building a minimal AROS guest OS for qemount to provide access to Amiga filesystems.

## Objectives

1. **AROS bootable image** for current ARCH (x86_64 initially) to run in QEMU
2. **Non-bootable mode** - boot AROS directly, not from attached disk images
3. **Minimal AROS** - just enough OS + simple9p server (target: <2MB like floppy builds, not 400MB full desktop)
4. **Build simple9p for AROS** - port/compile the 9p server for AROS

## Architecture Approach

- ~~Start from `common/compiler` (existing builder with standard build tools)~~
  - debian image for cross compilers since we need gl, we need a new root compiler
- Add AROS-specific build dependencies as needed (keep everything in one builder)
- Build minimal AROS ISO/image + simple9p in one shot
- Result: `guests/aros/` with bootable image + simple9p integrated

## Questions to Answer

### Build System
- [ ] What additional packages does AROS build need beyond what's in `common/compiler`?
- [ ] How to build minimal AROS (not full desktop) - is there a minimal target or configuration?
- [ ] What git tag/branch to use for stable, deterministic builds?
- [ ] How big is the minimal output image? (target: floppy-sized ~2MB)

### Boot and Runtime
- [ ] How does AROS boot in QEMU - ISO? HDF? Floppy image? What's the minimal boot path?
- [ ] What QEMU machine type and options for x86_64 AROS?
- [ ] How to prevent AROS from trying to boot attached disk images?

### simple9p Integration
- [ ] Where to integrate simple9p in the AROS build - compile into image or load at boot?
- [ ] Does simple9p need AROS-specific patches for sockets/networking?
- [ ] How to start simple9p automatically on boot?
- [ ] How to export mounted filesystems via 9p back to host?

## Research Notes

AROS nightly builds include x86_64 floppy disk sized images, suggesting minimal builds are feasible.

## Next Steps

1. Clone AROS source and explore build system interactively
2. Identify minimal build target and dependencies
3. Build test image and measure size
4. Test booting in QEMU
5. Port simple9p to AROS
6. Integrate and test filesystem access
