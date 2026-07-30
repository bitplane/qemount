ARG ARCH
FROM docker.io/haiku/toolchain-worker@sha256:2a3c021f09245984528741ba0e562b14aa0353c31ffc2c8477b34fe7cd60cf49
ARG ARCH

WORKDIR /src
RUN tar xzf /host/build/sources/haiku-r1beta5.tar.gz && \
    mv haiku-r1beta5 haiku

WORKDIR /src/haiku
RUN mkdir -p generated && \
    cd generated && \
    ../configure --cross-tools-prefix /toolchains/cross-tools-${ARCH}/bin/${ARCH}-unknown-haiku-
