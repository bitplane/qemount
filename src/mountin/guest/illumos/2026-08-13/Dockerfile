ARG ILLUMOS_BUILDER
FROM ${ILLUMOS_BUILDER}

ARG OUTPUT_ARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc-multilib \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 kernel-build.sh modules-build.sh boot-build.sh /build/
COPY modules.list configs.list boot.S /build/

RUN /build/kernel-build.sh
RUN /build/modules-build.sh
RUN /build/boot-build.sh

COPY --chmod=755 export.sh /build/export.sh
COPY root /build/root
ENTRYPOINT ["/build/export.sh"]
