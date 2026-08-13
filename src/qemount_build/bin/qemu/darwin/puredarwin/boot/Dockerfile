ARG BUILDER
FROM ${BUILDER}

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        autoconf \
        automake \
        autopoint \
        bison \
        flex \
        gawk \
        gcc-i686-linux-gnu \
        gettext \
        pkg-config \
        python3 \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
