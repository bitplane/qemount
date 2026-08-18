ARG MOUNTIN_BUILDER
FROM ${MOUNTIN_BUILDER}

ARG MOUNTIN_BUILD_ARCH
ARG MOUNTIN_BUILD_JOBS=1
ARG MOUNTIN_TARGET_ARCH

COPY --chmod=755 build.sh sysroot-build.sh /build/
COPY plockstat-stubs.c /build/plockstat-stubs.c

RUN /build/build.sh
RUN /build/sysroot-build.sh

COPY --chmod=0755 cc.sh /usr/local/bin/x86_64-illumos-cc
COPY --chmod=0755 ld.sh /usr/local/bin/x86_64-illumos-ld
RUN ln -s /usr/bin/ar /usr/local/bin/x86_64-illumos-ar && \
    ln -s /usr/bin/strip /usr/local/bin/x86_64-illumos-strip

ENV CC=x86_64-illumos-cc \
    AR=x86_64-illumos-ar \
    STRIP=x86_64-illumos-strip

WORKDIR /source/usr/src
