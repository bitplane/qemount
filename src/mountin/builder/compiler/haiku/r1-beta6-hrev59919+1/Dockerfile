ARG TARGET_ARCH
ARG HAIKU_REVISION
ARG BUILD_JOBS=1
FROM ghcr.io/haiku/toolchain-worker-master@sha256:b89005bb884ee4b127e59169ce28924460bfe7765f79d1ac186fb55fa5944ee6
ARG TARGET_ARCH
ARG HAIKU_REVISION

WORKDIR /src
RUN mkdir haiku && \
    tar xzf /host/build/sources/haiku-r1-beta6-hrev59919+1.tar.gz \
        -C haiku --strip-components=1

WORKDIR /src/haiku
RUN mkdir -p generated && \
    cd generated && \
    ../configure --cross-tools-prefix /toolchains/cross-tools-${TARGET_ARCH}/bin/${TARGET_ARCH}-unknown-haiku-

RUN cd generated && \
    jam -q -j"${BUILD_JOBS}" "-sHAIKU_REVISION=${HAIKU_REVISION}" \
        haiku_cross_devel_sysroot_${TARGET_ARCH}.hpkg && \
    mkdir -p /opt/haiku-sysroot && \
    LD_LIBRARY_PATH=objects/linux/lib \
        objects/linux/x86_64/release/tools/package/package extract \
        -C /opt/haiku-sysroot \
        objects/haiku/${TARGET_ARCH}/packaging/packages/haiku_cross_devel_sysroot_${TARGET_ARCH}.hpkg

RUN mkdir -p /opt/haiku-sysroot/boot/system && \
    ln -s ../../develop /opt/haiku-sysroot/boot/system/develop

COPY --chmod=755 cc.sh /usr/local/bin/haiku-cc

RUN set -eu; \
    TOOL_PREFIX=/toolchains/cross-tools-${TARGET_ARCH}/bin/${TARGET_ARCH}-unknown-haiku-; \
    mkdir -p /usr/local/libexec; \
    ln -s "${TOOL_PREFIX}gcc" /usr/local/libexec/haiku-gcc; \
    ln -s "${TOOL_PREFIX}ar" /usr/local/bin/haiku-ar; \
    ln -s "${TOOL_PREFIX}strip" /usr/local/bin/haiku-strip; \
    ln -s "${TOOL_PREFIX}readelf" /usr/local/bin/haiku-readelf

ENV HAIKU_SYSROOT=/opt/haiku-sysroot \
    CC=haiku-cc \
    AR=haiku-ar \
    STRIP=haiku-strip \
    READELF=haiku-readelf
