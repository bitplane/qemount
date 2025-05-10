FROM qemount-common-compiler-${ARCH}
ARG ARCH

# Install build dependencies
RUN apk add --no-cache \
    git \
    make \
    gcc \
    musl-dev \
    linux-headers

WORKDIR /build

# Copy our source files
COPY simple9p.c Makefile ./

# Build everything
RUN make all

# Install to output location
RUN make install ARCH=${ARCH}