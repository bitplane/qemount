ARG BUILDER
FROM ${BUILDER}

ARG JOBS=1
ARG QEMOUNT_CACHE_DIR

RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf \
    automake \
    autopoint \
    binutils-i686-linux-gnu \
    gcc-i686-linux-gnu \
    gettext \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 system-build.sh boot-build.sh /build/

RUN /build/system-build.sh
RUN /build/boot-build.sh
