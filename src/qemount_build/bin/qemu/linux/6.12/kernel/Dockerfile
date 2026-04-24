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
COPY --chmod=755 build.sh /build.sh
COPY kernel.config /kernel.config
COPY filesystems.config /filesystems.config
ENTRYPOINT ["/build.sh"]
