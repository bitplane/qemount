FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    podman \
    qemu-system-x86 \
    make \
    python3 \
    git \
    fuse \
    xz-utils

# Configure podman to use vfs driver (works inside containers)
RUN mkdir -p /etc/containers /var/lib/containers /run/containers && \
    printf '[storage]\ndriver = "vfs"\nrunroot = "/run/containers"\ngraphroot = "/var/lib/containers"\n' > /etc/containers/storage.conf

RUN git clone https://github.com/bitplane/qemount /src
WORKDIR /src

CMD ["make"]
