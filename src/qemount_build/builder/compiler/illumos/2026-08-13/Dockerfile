ARG BUILDER
FROM ${BUILDER}

ARG BUILD_ARCH
ARG JOBS=1
ARG OUTPUT_ARCH

COPY --chmod=755 build.sh sysroot-build.sh /build/
COPY plockstat-stubs.c /build/plockstat-stubs.c

RUN /build/build.sh
RUN /build/sysroot-build.sh

WORKDIR /source/usr/src
