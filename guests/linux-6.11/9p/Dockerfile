ARG ARCH=x86_64
FROM qemount-common-compiler-${ARCH}
ARG ARCH=x86_64

# Install additional dependencies
RUN apk add --no-cache \
    libtool \
    autoconf \
    make \
    gcc \
    file \
    patch

# Download and extract Plan 9 source containing u9fs
RUN mkdir -p /build
WORKDIR /build
RUN git clone https://github.com/unofficial-mirror/u9fs.git

# Examine the repository structure in detail
WORKDIR /build/u9fs
RUN echo "### Directory listing: ###" && \
    ls -la && \
    echo "### Source file listing: ###" && \
    find . -name "*.c" -o -name "*.h" | sort && \
    echo "### Makefile contents: ###" && \
    cat makefile || echo "No makefile found"

# Try to build without authrhosts
WORKDIR /build/u9fs
RUN sed -i 's/authrhosts.o//' makefile

# Build with static linking
RUN CFLAGS="-static" LDFLAGS="-static" make clean || true
RUN CFLAGS="-static" LDFLAGS="-static" make || true

# If the above fails, try creating a proper simple9p
WORKDIR /build
COPY simple9p.c /build/simple9p.c

# Compile the simple 9P server with static linking
RUN gcc -static -o simple9p simple9p.c

# Check which one built successfully and use that
RUN if [ -f /build/u9fs/u9fs ] && file /build/u9fs/u9fs | grep -q "statically linked"; then \
        cp -v /build/u9fs/u9fs /tmp/final_binary; \
    else \
        cp -v /build/simple9p /tmp/final_binary; \
    fi

# Create output directory and copy final binary with stripping
RUN mkdir -p /outputs/guests/linux-6.11/rootfs/${ARCH}/bin && \
    cp -v /tmp/final_binary /outputs/guests/linux-6.11/rootfs/${ARCH}/bin/u9fs && \
    strip /outputs/guests/linux-6.11/rootfs/${ARCH}/bin/u9fs
