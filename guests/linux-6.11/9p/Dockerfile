FROM qemount-compiler:${ARCH}
ARG ARCH=x86_64

# Install additional dependencies
RUN apk add --no-cache \
    zlib-dev \
    autoconf \
    automake

# Download and extract dropbear
WORKDIR /build
RUN wget https://matt