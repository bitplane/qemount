ARG BUILDER
FROM ${BUILDER}

ARG BUILD_PLATFORM
ARG JOBS=1
ARG OUTPUT_ARCH
ARG QEMOUNT_CACHE_DIR

RUN mkdir -p /usr/src /usr/obj && \
    tar -xf /host/build/sources/dragonfly-6.4.2.tar.gz \
        -C /usr/src --strip-components=1

COPY linux-build.patch /tmp/linux-build.patch

WORKDIR /usr/src

RUN patch -p1 < /tmp/linux-build.patch

# DragonFly's build invokes `make` recursively and requires BSD make syntax.
RUN ln -sf /usr/bin/bmake /usr/bin/make

COPY host-aout.h host-compat.c host-compat.h host-elf-hints.h host-elf.h host-elf32.h host-objformat.h host-pwd.h host-util.h host-xlocale.h /tmp/
RUN ln -s /tmp/host-util.h /tmp/util.h
RUN ln -s /tmp/host-elf-hints.h /tmp/elf-hints.h
RUN ln -s /tmp/host-objformat.h /tmp/objformat.h
RUN ln -s /tmp/host-xlocale.h /tmp/xlocale.h
RUN mkdir -p /tmp/sys && ln -s /tmp/host-elf32.h /tmp/sys/elf32.h
RUN ln -s /tmp/host-aout.h /tmp/a.out.h
RUN mkdir /tmp/dragonfly-include && \
    cp /usr/src/include/db.h /usr/src/include/mpool.h \
        /tmp/dragonfly-include/ && \
    cp /tmp/host-pwd.h /tmp/dragonfly-include/pwd.h
RUN set -eux; \
    cc -D_GNU_SOURCE -include /tmp/host-compat.h \
        -c /tmp/host-compat.c -o /tmp/host-compat.o; \
    cd /usr/src/usr.sbin/mtree; \
    cc \
        -D_GNU_SOURCE \
        -DEMBED_LIB_SRC \
        -DHAVE_NETDB_H \
        -DHAVE_STRUCT_STAT_ST_FLAGS=0 \
        -DNO_MD5 \
        -DNO_RMD160 \
        -DNO_SHA \
        -include /tmp/host-compat.h \
        -I/tmp \
        -I/usr/src/lib/libc/gen \
        $(pkg-config --cflags libbsd-overlay) \
        compare.c crc.c create.c excludes.c getid.c misc.c mtree.c only.c \
        pack_dev.c spec.c specspec.c stat_flags.c verify.c \
        /usr/src/lib/libc/gen/pwcache.c /tmp/host-compat.o \
        -o /usr/local/bin/mtree \
        $(pkg-config --libs libbsd-overlay)

RUN set -eu; \
    test "$OUTPUT_ARCH" = x86_64; \
    HOST_CPU_FAMILY=${BUILD_PLATFORM%%-*}; \
    CACHE_DIR=$QEMOUNT_CACHE_DIR; \
    SOURCE_HASH=$(sha256sum \
        /host/build/sources/dragonfly-6.4.2.tar.gz \
        /tmp/host-aout.h /tmp/host-compat.c /tmp/host-compat.h \
        /tmp/host-elf-hints.h /tmp/host-elf.h /tmp/host-elf32.h \
        /tmp/host-objformat.h /tmp/host-pwd.h /tmp/host-util.h \
        /tmp/host-xlocale.h /tmp/linux-build.patch \
        | sha256sum | cut -d ' ' -f 1); \
    if [ ! -e "$CACHE_DIR/.qemount-sources-$SOURCE_HASH" ]; then \
        rm -rf "$CACHE_DIR"; \
        mkdir -p "$CACHE_DIR"; \
        touch "$CACHE_DIR/.qemount-sources-$SOURCE_HASH"; \
    fi; \
    mkdir -p "$CACHE_DIR/obj"; \
    rmdir /usr/obj; \
    ln -s "$CACHE_DIR/obj" /usr/obj; \
    bmake -j"$JOBS" \
        BUILD_ARCH=x86_64 \
        HOST_CPU_FAMILY="$HOST_CPU_FAMILY" \
        HOST_CFLAGS="-D_GNU_SOURCE -DDRAGONFLY_LINUX_HOST -include /tmp/host-compat.h -I/usr/include/tirpc $(pkg-config --cflags libbsd-overlay)" \
        HOST_LDADD="/tmp/host-compat.o $(pkg-config --libs --static libbsd-overlay) -lresolv -ltirpc" \
        HOST_YACC=/usr/bin/byacc \
        MACHINE=x86_64 \
        MACHINE_ARCH=x86_64 \
        MACHINE_PLATFORM=pc64 \
        NOCLEAN=1 \
        NO_GAMES=1 \
        NO_SHARE=1 \
        TARGET_ARCH=x86_64 \
        TARGET_PLATFORM=pc64 \
        WORLD_VERSION=600401 \
        buildworld

ENV DRAGONFLY_SRC=/usr/src
ENV DRAGONFLY_OBJ=/usr/obj

WORKDIR /build
