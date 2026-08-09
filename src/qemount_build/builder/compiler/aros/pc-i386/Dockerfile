ARG BUILDER
FROM ${BUILDER}

ARG JOBS=1
ARG QEMOUNT_CACHE_DIR
ENV TAR_OPTIONS=--no-same-owner

RUN set -eu; \
    SOURCE_ARCHIVE=/host/build/sources/aros-qemount-2026-07-30.tar.gz; \
    SOURCE_HASH=$(sha256sum "$SOURCE_ARCHIVE" | cut -d ' ' -f 1); \
    CACHE_DIR=$QEMOUNT_CACHE_DIR; \
    SOURCE_DIR=$CACHE_DIR/source; \
    BUILD_DIR=$CACHE_DIR/toolchain-build; \
    INSTALL_DIR=$CACHE_DIR/toolchain; \
    export CCACHE_DIR=$CACHE_DIR/ccache; \
    mkdir -p "$CACHE_DIR" "$CCACHE_DIR"; \
    if [ ! -f "$CACHE_DIR/.source-$SOURCE_HASH" ]; then \
        rm -rf "$SOURCE_DIR" "$BUILD_DIR" "$INSTALL_DIR"; \
        mkdir -p "$SOURCE_DIR"; \
        tar -xzf "$SOURCE_ARCHIVE" -C "$SOURCE_DIR" --strip-components=1; \
        rm -f "$CACHE_DIR"/.source-*; \
        touch "$CACHE_DIR/.source-$SOURCE_HASH"; \
    fi; \
    mkdir -p "$BUILD_DIR" "$INSTALL_DIR"; \
    cd "$BUILD_DIR"; \
    "$SOURCE_DIR/configure" \
        --target=pc-i386 \
        --enable-target-variant=tiny \
        --enable-build-type=nightly \
        --enable-ccache \
        --with-portssources=/host/build/sources/aros-ports \
        --with-aros-toolchain-install="$INSTALL_DIR" \
        --with-optimization="-Os -fno-defer-pop -mpreferred-stack-boundary=4" \
    ; \
    make -j"${JOBS}" crosstools; \
    rm -rf /opt/aros-toolchain; \
    cp -a "$INSTALL_DIR" /opt/aros-toolchain
