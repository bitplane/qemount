FROM builder/compiler/haiku

ARG MOUNTIN_TARGET_ARCH
ARG MOUNTIN_HAIKU_REVISION
ARG MOUNTIN_BUILD_JOBS=1
ARG MOUNTIN_CACHE_DIR

WORKDIR /src
RUN mkdir haiku buildtools && \
    tar -xzf /host/build/sources/haiku-r1-beta6-hrev59919+1.tar.gz \
        -C haiku --strip-components=1 && \
    tar -xzf /host/build/sources/haiku-buildtools-2026-05-20.tar.gz \
        -C buildtools --strip-components=1

RUN set -eu; \
    cd /src/buildtools/jam; \
    make -j"$MOUNTIN_BUILD_JOBS"; \
    ./jam0 install

RUN set -eu; \
    cache=$MOUNTIN_CACHE_DIR; \
    cached_toolchain=$cache/cross-tools-${MOUNTIN_TARGET_ARCH}; \
    compiler=$cached_toolchain/bin/${MOUNTIN_TARGET_ARCH}-unknown-haiku-gcc; \
    if [ ! -x "$compiler" ]; then \
        rm -rf "$cached_toolchain" "$cached_toolchain-build"; \
        machine=$(/src/haiku/build/scripts/find_triplet "$MOUNTIN_TARGET_ARCH"); \
        /src/haiku/build/scripts/build_cross_tools_gcc4 \
            "$machine" /src/haiku /src/buildtools "$cached_toolchain" \
            -j"$MOUNTIN_BUILD_JOBS"; \
    fi; \
    mkdir -p /toolchains; \
    cp -a "$cached_toolchain" /toolchains/

WORKDIR /src/haiku
RUN mkdir -p generated && \
    cd generated && \
    ../configure --cross-tools-prefix /toolchains/cross-tools-${MOUNTIN_TARGET_ARCH}/bin/${MOUNTIN_TARGET_ARCH}-unknown-haiku-

RUN set -eu; \
    cd generated; \
    jam -q -j"${MOUNTIN_BUILD_JOBS}" \
        "-sHAIKU_REVISION=${MOUNTIN_HAIKU_REVISION}" \
        haiku_cross_devel_sysroot_${MOUNTIN_TARGET_ARCH}.hpkg; \
    package=$(find objects/linux -type f \
        -path '*/release/tools/package/package' -print -quit); \
    test -n "$package"; \
    mkdir -p /opt/haiku-sysroot; \
    LD_LIBRARY_PATH=objects/linux/lib \
        "$package" extract \
        -C /opt/haiku-sysroot \
        objects/haiku/${MOUNTIN_TARGET_ARCH}/packaging/packages/haiku_cross_devel_sysroot_${MOUNTIN_TARGET_ARCH}.hpkg

RUN mkdir -p /opt/haiku-sysroot/boot/system && \
    ln -s ../../develop /opt/haiku-sysroot/boot/system/develop

COPY --chmod=755 cc.sh /usr/local/bin/haiku-cc

RUN set -eu; \
    TOOL_PREFIX=/toolchains/cross-tools-${MOUNTIN_TARGET_ARCH}/bin/${MOUNTIN_TARGET_ARCH}-unknown-haiku-; \
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
