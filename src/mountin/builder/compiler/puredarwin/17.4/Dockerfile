ARG MOUNTIN_BUILDER
FROM ${MOUNTIN_BUILDER}

ARG MOUNTIN_BUILD_JOBS=1
ARG MOUNTIN_CACHE_DIR

RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf \
    automake \
    autopoint \
    binutils-i686-linux-gnu \
    gcc-i686-linux-gnu \
    gettext \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 system-build.sh boot-build.sh /build/

RUN /build/system-build.sh
RUN /build/boot-build.sh

COPY --chmod=755 cc.sh /usr/local/bin/puredarwin-cc

RUN ln -s /usr/bin/llvm-ar-14 /usr/local/bin/puredarwin-ar && \
    ln -s /usr/bin/llvm-strip-14 /usr/local/bin/puredarwin-strip && \
    ln -s /usr/bin/llvm-objdump-14 /usr/local/bin/puredarwin-objdump

ENV PUREDARWIN_SYSROOT=/opt/puredarwin/sysroot \
    CC=puredarwin-cc \
    AR=puredarwin-ar \
    STRIP=puredarwin-strip \
    OBJDUMP=puredarwin-objdump
