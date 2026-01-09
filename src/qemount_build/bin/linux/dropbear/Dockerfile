ARG BUILDER
FROM ${BUILDER}

RUN apk add --no-cache \
    zlib-dev \
    autoconf \
    automake

WORKDIR /work
ADD build.sh /build.sh
RUN chmod +x /build.sh
