FROM builder/compiler/linux

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
    link_source /host/build/sources/gcc-5.3.0.tar.bz2 "$sources/gcc-5.3.0.tar.bz2"; \
    link_source /host/build/sources/binutils-2.25.1.tar.bz2 "$sources/binutils-2.25.1.tar.bz2"; \
    link_source /host/build/sources/musl-1.2.6.tar.gz "$sources/musl-1.2.6.tar.gz"; \
    link_source /host/build/sources/gmp-6.3.0.tar.xz "$sources/gmp-6.3.0.tar.xz"; \
    link_source /host/build/sources/mpc-1.3.1.tar.gz "$sources/mpc-1.3.1.tar.gz"; \
    link_source /host/build/sources/mpfr-4.2.2.tar.xz "$sources/mpfr-4.2.2.tar.xz"; \
    link_source /host/build/sources/linux-2.6.39.4.tar.xz "$sources/linux-2.6.39.4.tar.xz"; \
    cd "$source"; \
    config=config.mak; \
    config_new=$config.new; \
    printf '%s\n' \
        'TARGET = x86_64-linux-musl' \
        'OUTPUT = /opt/cross' \
        "SOURCES = $sources" \
        'BINUTILS_VER = 2.25.1' \
        'GCC_VER = 5.3.0' \
        'MUSL_VER = 1.2.6' \
        'GMP_VER = 6.3.0' \
        'MPC_VER = 1.3.1' \
        'MPFR_VER = 4.2.2' \
        'LINUX_VER = 2.6.39.4' \
        'MAKE += HOSTCFLAGS=-std=gnu89' \
        "COMMON_CONFIG += --disable-nls --with-debug-prefix-map=$source=." \
        'GCC_CONFIG += --enable-languages=c --disable-libquadmath --disable-decimal-float --disable-libitm --disable-fixed-point --disable-lto' \
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
ENV CROSS_COMPILE=x86_64-linux-musl-
ENV CC=x86_64-linux-musl-gcc
ENV LD=x86_64-linux-musl-ld
ENV AR=x86_64-linux-musl-ar
ENV AS=x86_64-linux-musl-as
ENV NM=x86_64-linux-musl-nm
ENV RANLIB=x86_64-linux-musl-ranlib
ENV STRIP=x86_64-linux-musl-strip
ENV OBJCOPY=x86_64-linux-musl-objcopy
ENV READELF=x86_64-linux-musl-readelf

WORKDIR /build
