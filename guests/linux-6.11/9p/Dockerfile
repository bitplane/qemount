ARG ARCH=x86_64
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

# Clone libixp
RUN git clone --depth 1 https://github.com/0intro/libixp.git

# Copy our source files
COPY . ./

# Build everything
RUN make


RUN mkdir -p /outputs/guests/linux-6.11/rootfs/${ARCH}/bin
RUN cp    -v /build/build/simple9p /outputs/guests/linux-6.11/rootfs/${ARCH}/bin/

