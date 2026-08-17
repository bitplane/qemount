ARG BUILDER
FROM ${BUILDER}

COPY kernel-build.patch /tmp/kernel-build.patch
RUN patch -d /usr/src -p1 < /tmp/kernel-build.patch
COPY MOUNTIN /usr/src/sys/config/MOUNTIN

RUN apt-get update && apt-get install -y --no-install-recommends \
    xorriso \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 build.sh assemble-root.py mountin-rc /build/
COPY runtime-files.txt loader.conf dloader.rc /build/

ENTRYPOINT ["/build/build.sh"]
