FROM alpine:latest

# QEMU base image for building filesystems that need mount access
# The kernel and boot.img are accessed from /host/build at runtime
RUN apk add --no-cache \
    qemu-system-x86_64 bash e2fsprogs-extra \
    xfsprogs jfsutils f2fs-tools bcachefs-tools hfsprogs util-linux \
    udftools nilfs-utils
