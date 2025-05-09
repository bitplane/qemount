# Linux 6.11 Guest

Linux kernel with busybox. Can mount any filesystems that are built in. and
expose them over multiple transports for the user to consume via FUSE or other
non-root methods.

## linux

todo: build in Docker and figure out what is required to make it work

## busybox

todo: build in Docker and figure out what is required to make it work

## u9fs (9P Server)

The project uses u9fs, a simple 9P server implementation from Plan 9. It's statically compiled
to ensure it can run within the minimal environment of the VM.

## nbd

todo: figure out an nbd server