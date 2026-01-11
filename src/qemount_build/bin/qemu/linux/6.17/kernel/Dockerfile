ARG BUILDER
FROM ${BUILDER}

RUN apk add --no-cache \
    bc \
    bison \
    flex \
    elfutils-dev \
    openssl-dev \
    perl \
    python3 \
    ncurses-dev \
    xz \
    rsync \
    bash

WORKDIR /work
ADD build.sh /build.sh
ADD kernel.config /kernel.config
ADD filesystems.config /filesystems.config
RUN chmod +x /build.sh
ENTRYPOINT ["/build.sh"]
