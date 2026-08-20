FROM builder/compiler/linux

ARG MOUNTIN_TARGET_PLATFORM
ARG MOUNTIN_BUILD_JOBS=1
ARG MOUNTIN_CACHE_DIR

RUN set -eu; \
    cache=$MOUNTIN_CACHE_DIR; \
    source=$cache/musl-cross-make; \
    sources=$cache/sources; \
    mkdir -p "$cache" "$sources"; \
    if [ ! -d "$source" ]; then \
        temporary=$cache/musl-cross-make.tmp.$$; \
        rm -rf "$temporary"; \
        mkdir -p "$temporary"; \
        tar -xzf /host/build/sources/musl-cross-make-2026-08-20.tar.gz \
            -C "$temporary" --strip-components=1; \
        mv "$temporary" "$source"; \
    fi; \
    if grep -qE 'tar [zjJ]xvf' "$source/Makefile"; then \
        sed -i \
            -e 's/tar zxvf/tar zxf/g' \
            -e 's/tar jxvf/tar jxf/g' \
            -e 's/tar Jxvf/tar Jxf/g' \
            "$source/Makefile"; \
    fi; \
    link_source() { \
        target=$1; \
        link=$2; \
        [ -L "$link" ] && [ "$(readlink "$link")" = "$target" ] \
            || ln -sf "$target" "$link"; \
    }; \
    link_source /host/build/sources/gcc-9.4.0.tar.xz "$sources/gcc-9.4.0.tar.xz"; \
    link_source /host/build/sources/binutils-2.44.tar.gz "$sources/binutils-2.44.tar.gz"; \
    link_source /host/build/sources/musl-1.2.6.tar.gz "$sources/musl-1.2.6.tar.gz"; \
    link_source /host/build/sources/gmp-6.3.0.tar.xz "$sources/gmp-6.3.0.tar.xz"; \
    link_source /host/build/sources/mpc-1.3.1.tar.gz "$sources/mpc-1.3.1.tar.gz"; \
    link_source /host/build/sources/mpfr-4.2.2.tar.xz "$sources/mpfr-4.2.2.tar.xz"; \
    config_sub=$sources/config.sub; \
    config_sub_new=$config_sub.new; \
    tar -xOf /host/build/sources/gcc-9.4.0.tar.xz gcc-9.4.0/config.sub \
        > "$config_sub_new"; \
    if cmp -s "$config_sub_new" "$config_sub"; then \
        rm "$config_sub_new"; \
    else \
        mv "$config_sub_new" "$config_sub"; \
    fi; \
    link_source /host/build/sources/linux-6.12.tar.xz "$sources/linux-6.12.83.tar.xz"; \
    cd "$source"; \
    config=config.mak; \
    config_new=$config.new; \
    printf '%s\n' \
        "TARGET = $MOUNTIN_TARGET_PLATFORM" \
        'OUTPUT = /opt/cross' \
        "SOURCES = $sources" \
        'BINUTILS_VER = 2.44' \
        'GCC_VER = 9.4.0' \
        'MUSL_VER = 1.2.6' \
        'GMP_VER = 6.3.0' \
        'MPC_VER = 1.3.1' \
        'MPFR_VER = 4.2.2' \
        'LINUX_VER = 6.12.83' \
        "COMMON_CONFIG += --disable-nls --with-debug-prefix-map=$source=." \
        'GCC_CONFIG += --enable-languages=c --disable-libquadmath --disable-decimal-float --disable-libitm --disable-fixed-point' \
        > "$config_new"; \
    if cmp -s "$config_new" "$config"; then \
        rm "$config_new"; \
    else \
        mv "$config_new" "$config"; \
    fi; \
    make -j"$MOUNTIN_BUILD_JOBS"; \
    rm -rf /opt/cross; \
    make install

ENV PATH=/opt/cross/bin:$PATH
ENV CROSS_COMPILE=${MOUNTIN_TARGET_PLATFORM}-
ENV CC=${MOUNTIN_TARGET_PLATFORM}-gcc
ENV LD=${MOUNTIN_TARGET_PLATFORM}-ld
ENV AR=${MOUNTIN_TARGET_PLATFORM}-ar
ENV AS=${MOUNTIN_TARGET_PLATFORM}-as
ENV NM=${MOUNTIN_TARGET_PLATFORM}-nm
ENV RANLIB=${MOUNTIN_TARGET_PLATFORM}-ranlib
ENV STRIP=${MOUNTIN_TARGET_PLATFORM}-strip
ENV OBJCOPY=${MOUNTIN_TARGET_PLATFORM}-objcopy
ENV READELF=${MOUNTIN_TARGET_PLATFORM}-readelf
ENV CHOST=${MOUNTIN_TARGET_PLATFORM}

WORKDIR /build
