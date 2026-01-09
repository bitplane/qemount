ARG BUILDER
FROM ${BUILDER}

RUN apk add --no-cache \
    make \
    gcc \
    musl-dev \
    linux-headers

WORKDIR /work
ADD build.sh /build.sh
RUN chmod +x /build.sh
