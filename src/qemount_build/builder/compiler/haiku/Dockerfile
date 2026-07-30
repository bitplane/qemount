ARG ARCH
FROM ghcr.io/haiku/toolchain-worker-master@sha256:b89005bb884ee4b127e59169ce28924460bfe7765f79d1ac186fb55fa5944ee6
ARG ARCH

WORKDIR /src
RUN tar xzf /host/build/sources/haiku-r1beta5.tar.gz && \
    mv haiku-r1beta5 haiku

WORKDIR /src/haiku
RUN mkdir -p generated && \
    cd generated && \
    ../configure --cross-tools-prefix /toolchains/cross-tools-${ARCH}/bin/${ARCH}-unknown-haiku-
