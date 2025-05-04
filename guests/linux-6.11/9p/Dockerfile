ARG ARCH=x86_64
FROM qemount-builder-native:${ARCH}

# Download and extract
RUN mkdir -p /build
WORKDIR /build
RUN wget https://github.com/chaos/diod/releases/download/1.0.24/diod-1.0.24.tar.gz
RUN tar -xzf diod-1.0.24.tar.gz

# Configure
WORKDIR /build/diod-1.0.24
RUN ./configure

# Build
RUN make
