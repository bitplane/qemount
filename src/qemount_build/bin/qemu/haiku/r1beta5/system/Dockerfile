ARG BUILDER
FROM ${BUILDER}

ARG ARCH
ARG JOBS=1
ENV ARCH=${ARCH}
ENV JOBS=${JOBS}

WORKDIR /src/haiku/generated
COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
