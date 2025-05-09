ARG ARCH=x86_64
FROM qemount-builder-native:${ARCH}

# Download and extract Plan 9 source containing u9fs
RUN mkdir -p /build
WORKDIR /build
RUN git clone https://github.com/unofficial-mirror/u9fs.git

# Build u9fs with static linking
WORKDIR /build/u9fs
RUN make LDFLAGS="-static"

# The built binary will be at /build/u9fs/u9fs
