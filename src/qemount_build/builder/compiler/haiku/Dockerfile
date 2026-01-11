ARG ARCH
FROM docker.io/haiku/toolchain-worker:latest
ARG ARCH

WORKDIR /src
RUN tar xzf /host/build/sources/haiku-r1beta5.tar.gz && \
    mv haiku-r1beta5 haiku

WORKDIR /src/haiku
RUN mkdir -p generated && \
    cd generated && \
    ../configure --cross-tools-prefix /toolchains/cross-tools-${ARCH}/bin/${ARCH}-unknown-haiku-
