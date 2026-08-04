ARG BUILDER
FROM ${BUILDER}

COPY kernel-build.patch /tmp/kernel-build.patch
RUN patch -d /usr/src -p1 < /tmp/kernel-build.patch

RUN apt-get update && apt-get install -y --no-install-recommends \
    xorriso \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 build.sh /build.sh

ENTRYPOINT ["/build.sh"]
