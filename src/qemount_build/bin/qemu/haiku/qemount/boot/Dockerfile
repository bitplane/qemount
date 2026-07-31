ARG BUILDER
FROM ${BUILDER}

ARG ARCH
ENV ARCH=${ARCH}

WORKDIR /work
COPY --chmod=755 build.sh /build.sh
COPY --chmod=755 UserBootscript /UserBootscript
COPY qemount.launch /qemount.launch
ENTRYPOINT ["/build.sh"]
