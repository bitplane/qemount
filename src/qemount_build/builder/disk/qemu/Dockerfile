FROM alpine:latest

RUN apk add --no-cache \
    bash tar jq \
    qemu-system-x86_64 qemu-system-aarch64 \
    e2fsprogs e2fsprogs-extra \
    xfsprogs jfsutils f2fs-tools hfsprogs \
    udftools nilfs-utils exfatprogs ntfs-3g-progs \
    util-linux

# bcachefs-tools not in alpine repos yet, skip for now

WORKDIR /build
COPY build.sh /build/build.sh
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]
