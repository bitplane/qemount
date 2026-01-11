ARG ARCH
FROM docker.io/haiku/toolchain-worker:latest
ARG ARCH

WORKDIR /src
RUN git clone https://github.com/haiku/haiku.git && \
    cd haiku && \
    git checkout r1beta5

WORKDIR /src/haiku
RUN mkdir -p generated && \
    cd generated && \
    ../configure --cross-tools-prefix /toolchains/cross-tools-${ARCH}/bin/${ARCH}-unknown-haiku-
