# Linux 6.11 Guest

Linux kernel with busybox. Can mount any filesystems that are built in. and
expose them over multiple transports for the user to consume via FUSE or other
non-root methods.

## filesystem support

todo: cat /proc/filesystems

## u9fs (9P Server)

This is a bit of a mess. We need cross compilation and also static builds. We
should probably just lift the code and drop it in here. It's not like it's
changed recently.
