ARG ARCH
FROM ghcr.io/haiku/toolchain-worker-master@sha256:b89005bb884ee4b127e59169ce28924460bfe7765f79d1ac186fb55fa5944ee6
ARG ARCH

WORKDIR /src
RUN mkdir haiku && \
    tar xzf /host/build/sources/haiku-qemount-2026-07-31.tar.gz \
        -C haiku --strip-components=1

WORKDIR /src/haiku
RUN mkdir -p generated && \
    cd generated && \
    ../configure --cross-tools-prefix /toolchains/cross-tools-${ARCH}/bin/${ARCH}-unknown-haiku-
