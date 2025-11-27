# Linux 6.11 Guest

Linux kernel with busybox. Can mount any filesystems that are built in. and
expose them over multiple transports for the user to consume via FUSE or other
non-root methods.

## filesystem support

```
reiserfs ext3 ext4 ext2 cramfs squashfs minix vfat msdos exfat bfs iso9660
hfsplus hfs vxfs sysv v7 hpfs ntfs3 ufs efs affs romfs qnx4 qnx6 adfs fuseblk
udf omfs jfs xfs nilfs2 befs gfs2 gfs2meta f2fs bcachefs erofs btrfs
```

## u9fs (9P Server)

This is a bit of a mess. We need cross compilation and also static builds. We
should probably just lift the code and drop it in here. It's not like it's
changed recently.

## dropbear (ssh server)

This builds, but can't get it to serve over a socket.
