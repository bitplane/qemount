ARG ARCH
FROM qemount-common-compiler-${ARCH}
ARG ARCH
ARG ARCH_VARIANT=""

# OUR standard naming - consistent everywhere
ENV TARGET_TRIPLE=${ARCH}-linux-musl${ARCH_VARIANT}
ENV CROSS_COMPILE=${TARGET_TRIPLE}-

# Standard environment for all builds
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

# Copy setup scripts
COPY setup-native.sh setup-cross.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup-*.sh

# Run appropriate setup based on architecture
RUN if [ "$(uname -m)" = "$ARCH" ]; then \
        /usr/local/bin/setup-native.sh; \
    else \
        /usr/local/bin/setup-cross.sh "$ARCH"; \
    fi

# Create standard directories
RUN mkdir -p /build /outputs /host/build

# Default working directory
WORKDIR /build

# Copy deployment script
COPY --chmod=755 deploy.sh /usr/local/bin/deploy.sh
ENTRYPOINT ["/usr/local/bin/deploy.sh"]