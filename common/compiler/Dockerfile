FROM alpine:latest

# Install basic build tools
RUN apk update && apk add --no-cache \
    build-base \
    gcc \
    g++ \
    make \
    cmake \
    automake \
    autoconf \
    libtool \
    pkgconfig \
    curl \
    wget \
    git \
    python3 \
    linux-headers \
    musl-dev \
    file \
    bison \
    flex \
    ncurses-dev \
    elfutils-dev \
    openssl-dev \
    xz \
    tar \
    bc \
    mtools \
    cpio \
    zlib-dev

# Create build directories
RUN mkdir -p /build /outputs /host/build

# Set default environment for static builds
ENV CFLAGS="-static"
ENV CXXFLAGS="-static"
ENV LDFLAGS="-static"

# Default working directory
WORKDIR /build

COPY --chmod=755 deploy.sh /usr/local/bin/deploy.sh
ENTRYPOINT ["/usr/local/bin/deploy.sh"]
