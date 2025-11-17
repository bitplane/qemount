# AROS Guest

Building a minimal AROS guest OS for qemount to provide access to Amiga filesystems.

## Objectives

1. **AROS bootable image** for current ARCH (i386 initially) to run in QEMU
2. **Non-bootable mode** - boot AROS directly, not from attached disk images
3. **Minimal AROS** - just enough OS + simple9p server (target: <2MB like floppy builds, not 400MB full desktop)
4. **Build simple9p for AROS** - port/compile the 9p server for AROS

## Notes

- we had to fork aros, no tags for stability, some build errors on master
- cross compiler setup + minimal build was a pain as usual

## Questions to Answer

### Boot and Runtime
- [ ] How does AROS boot in QEMU - ISO? HDF? Floppy image? What's the minimal boot path?
- [ ] What QEMU machine type and options for x86_64 AROS?
- [ ] How to prevent AROS from trying to boot attached disk images?

### simple9p Integration
- [ ] Where to integrate simple9p in the AROS build - compile into image or load at boot?
- [ ] How to pipe stdio to serial
- [ ] How to start simple9p automatically on boot?
- [ ] How to export mounted filesystems via 9p back to host?

## Next Steps

- [x] Clone AROS source and explore build system interactively
- [x] Identify minimal build target and dependencies
- [ ] Build test image and measure size
- [ ] Test booting in QEMU
- [ ] Port simple9p to AROS
- [ ] Integrate and test filesystem access
- [ ] Test with disk images + filesystem variants
