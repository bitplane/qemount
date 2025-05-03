# Native builder image for qemount build system
ARG ARCH=x86_64
FROM qemount-builder-base:${ARCH}

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install native build tools - additional development packages useful for native compilation
RUN apt-get update && apt-get install -y \
    # Development tools
    gdb \
    valgrind \
    strace \
    ltrace \
    # Documentation
    man-db \
    # Build optimization tools
    ccache \
    distcc \
    # Additional libraries
    libffi-dev \
    libglib2.0-dev \
    libpcre3-dev \
    libxml2-dev \
    zlib1g-dev \
    # Useful utilities
    lsb-release \
    file \
    && rm -rf /var/lib/apt/lists/*

# Set up ccache for faster builds
ENV PATH=/usr/lib/ccache:${PATH}
ENV CCACHE_DIR=/cache/ccache

# Create builds directory for native compilation
RUN mkdir -p /builds

# Set working directory
WORKDIR /builds

# Add a version identifier
RUN echo "qemount-builder-native:${HOST_ARCH}" > /etc/qemount-builder-version