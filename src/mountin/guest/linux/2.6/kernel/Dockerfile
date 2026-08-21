ARG MOUNTIN_BUILDER
FROM ${MOUNTIN_BUILDER}

WORKDIR /work
COPY --chmod=755 build.sh /build.sh
COPY kernel.config /kernel.config
COPY filesystems.config /filesystems.config
COPY compiler-gcc5.h /compiler-gcc5.h
COPY modern-perl.patch /modern-perl.patch
ENTRYPOINT ["/build.sh"]
