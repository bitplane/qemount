ARG BUILDER
FROM ${BUILDER}

RUN apk add --no-cache \
    linux-headers \
    readline-dev \
    openssl-dev

WORKDIR /work
ADD build.sh /build.sh
RUN chmod +x /build.sh
