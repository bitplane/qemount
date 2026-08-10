ARG BUILDER
FROM ${BUILDER}

ARG JOBS=1
ARG QEMOUNT_CACHE_DIR
ENV TAR_OPTIONS=--no-same-owner

RUN set -eu; \
    SOURCE_ARCHIVE=/host/build/sources/aros-qemount-2026-07-30.tar.gz; \
    CACHE_DIR=$QEMOUNT_CACHE_DIR; \
    SOURCE_DIR=$CACHE_DIR/source; \
    BUILD_DIR=$CACHE_DIR/toolchain-build; \
    INSTALL_DIR=/opt/aros-toolchain; \
    export CCACHE_DIR=$CACHE_DIR/ccache; \
    mkdir -p "$CACHE_DIR" "$CCACHE_DIR" "$INSTALL_DIR"; \
    if [ ! -d "$SOURCE_DIR" ]; then \
        TEMPORARY=$CACHE_DIR/source.tmp.$$; \
        rm -rf "$TEMPORARY"; \
        mkdir -p "$TEMPORARY"; \
        tar --no-same-owner -xzf "$SOURCE_ARCHIVE" \
            -C "$TEMPORARY" --strip-components=1; \
        mv "$TEMPORARY" "$SOURCE_DIR"; \
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
    mkdir -p \
        /opt/aros-bootstrap/bin/pc-i386-tiny/AROS \
        /opt/aros-bootstrap/bin/linux-x86_64/tools; \
    cp -a \
        "$BUILD_DIR/bin/pc-i386-tiny/AROS/Developer" \
        /opt/aros-bootstrap/bin/pc-i386-tiny/AROS/; \
    cp -a \
        "$BUILD_DIR/bin/linux-x86_64/tools/collect-aros" \
        /opt/aros-bootstrap/bin/linux-x86_64/tools/
