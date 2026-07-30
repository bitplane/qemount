ARG BUILDER
FROM ${BUILDER}

ARG JOBS=1
ENV TAR_OPTIONS=--no-same-owner

RUN mkdir -p /work/source /work/toolchain-build \
        /opt/aros-toolchain /opt/aros-portssources \
    && tar -xzf /host/build/sources/aros-qemount-2026-07-30.tar.gz \
        -C /work/source --strip-components=1 \
    && cd /work/toolchain-build \
    && /work/source/configure \
        --target=pc-i386 \
        --enable-target-variant=tiny \
        --enable-build-type=nightly \
        --enable-ccache \
        --with-portssources=/opt/aros-portssources \
        --with-aros-toolchain-install=/opt/aros-toolchain \
        --with-optimization="-Os -fno-defer-pop -mpreferred-stack-boundary=4" \
    && make -j"${JOBS}" crosstools \
    && rm -rf /work/source /work/toolchain-build
