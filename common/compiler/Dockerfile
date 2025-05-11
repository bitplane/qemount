FROM alpine:latest
ARG ARCH
ARG ARCH_VARIANT=""

# Install native build tools
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
    zlib-dev \
    patch \
    findutils


COPY setup-native.sh setup-cross.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup-*.sh

RUN if [ "$(uname -m)" = "$ARCH" ]; then \
        /usr/local/bin/setup-native.sh; \
    else \
        /usr/local/bin/setup-cross.sh "$ARCH" "$TARGET_TRIPLE"; \
    fi

# Set up standard environment
ENV PATH="/opt/${ARCH}-linux-musl${ARCH_VARIANT}-cross/bin:${PATH}"
ENV CC=target-gcc
ENV CXX=target-g++
ENV LD=target-ld
ENV AR=target-ar
ENV STRIP=target-strip
ENV OBJCOPY=target-objcopy
ENV NM=target-nm
ENV CFLAGS="-static"
ENV CXXFLAGS="-static"
ENV LDFLAGS="-static"
ENV CROSS_COMPILE=${ARCH}-linux-musl${ARCH_VARIANT}-

# Create standard directories
RUN mkdir -p /build /outputs /host/build

# Default working directory
WORKDIR /build

# Copy deployment script
COPY --chmod=755 deploy.sh /usr/local/bin/deploy.sh
ENTRYPOINT ["/usr/local/bin/deploy.sh"]
