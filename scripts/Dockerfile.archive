FROM docker.io/library/ubuntu:24.04

RUN apt-get update && apt-get install -y \
    podman \
    fuse-overlayfs \
    qemu-system-x86 \
    make \
    python3 \
    git \
    xz-utils

# Configure podman to use overlay driver (fast with --privileged)
RUN mkdir -p /etc/containers /var/lib/containers /run/containers && \
    printf '[storage]\ndriver = "overlay"\nrunroot = "/run/containers"\ngraphroot = "/var/lib/containers"\n[storage.options.overlay]\nmount_program = "/usr/bin/fuse-overlayfs"\n' > /etc/containers/storage.conf

RUN git clone https://github.com/bitplane/qemount /src
WORKDIR /src

CMD ["make"]
