FROM alpine:latest
ARG ARCH

# Install build tools
RUN apk add --no-cache \
    build-base \
    musl-dev \
    linux-headers \
    bash \
    git \
    findutils \
    python3 \
    py3-pip \
    automake \
    autoconf \
    bison \
    flex \
    texinfo \
    libpng-dev \
    curl \
    gmp-dev \
    mpfr-dev \
    mpc1-dev

# Set compiler variables explicitly
ENV CC=gcc
ENV CXX=g++
ENV LD=ld
ENV AR=ar
ENV STRIP=strip
ENV NM=nm

# Standard build flags for static binaries
ENV CFLAGS="-static"
ENV CXXFLAGS="-static"
ENV LDFLAGS="-static"

# Create directories
RUN mkdir -p /build /outputs /host/build
WORKDIR /build

# Copy deployment script
COPY --chmod=755 deploy.sh /usr/local/bin/deploy.sh
ENTRYPOINT ["/usr/local/bin/deploy.sh"]
