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
    patch

# Set up compiler for target architecture  
RUN BUILD_ARCH=$(uname -m) && \
    TARGET_TRIPLE="${ARCH}-linux-musl${ARCH_VARIANT}" && \
    echo "Build arch: $BUILD_ARCH" && \
    echo "Target triple: $TARGET_TRIPLE" && \
    if [ "$BUILD_ARCH" = "$ARCH" ] && [ -z "$ARCH_VARIANT" ]; then \
        echo "Native compilation" && \
        ln -s /usr/bin/gcc /usr/bin/target-gcc && \
        ln -s /usr/bin/g++ /usr/bin/target-g++ && \
        ln -s /usr/bin/ld /usr/bin/target-ld && \
        ln -s /usr/bin/ar /usr/bin/target-ar && \
        ln -s /usr/bin/strip /usr/bin/target-strip && \
        ln -s /usr/bin/objcopy /usr/bin/target-objcopy && \
        ln -s /usr/bin/nm /usr/bin/target-nm; \
    else \
        echo "Cross compilation for $TARGET_TRIPLE" && \
        wget -qO- "https://musl.cc/${TARGET_TRIPLE}-cross.tgz" | tar -xz -C /opt/ && \
        ln -s "/opt/${TARGET_TRIPLE}-cross/bin/${TARGET_TRIPLE}-gcc" /usr/bin/target-gcc && \
        ln -s "/opt/${TARGET_TRIPLE}-cross/bin/${TARGET_TRIPLE}-g++" /usr/bin/target-g++ && \
        ln -s "/opt/${TARGET_TRIPLE}-cross/bin/${TARGET_TRIPLE}-ld" /usr/bin/target-ld && \
        ln -s "/opt/${TARGET_TRIPLE}-cross/bin/${TARGET_TRIPLE}-ar" /usr/bin/target-ar && \
        ln -s "/opt/${TARGET_TRIPLE}-cross/bin/${TARGET_TRIPLE}-strip" /usr/bin/target-strip && \
        ln -s "/opt/${TARGET_TRIPLE}-cross/bin/${TARGET_TRIPLE}-objcopy" /usr/bin/target-objcopy && \
        ln -s "/opt/${TARGET_TRIPLE}-cross/bin/${TARGET_TRIPLE}-nm" /usr/bin/target-nm; \
    fi

# Set up standard environment
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

# Create standard directories
RUN mkdir -p /build /outputs /host/build

# Default working directory
WORKDIR /build

# Copy deployment script
COPY --chmod=755 deploy.sh /usr/local/bin/deploy.sh
ENTRYPOINT ["/usr/local/bin/deploy.sh"]
