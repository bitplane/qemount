ARG ARCH
FROM localhost/qemount-common-compiler-linux-6-${ARCH}
ARG ARCH

# Install cramfs-tools dependencies including static zlib
RUN apk add --no-cache \
    zlib-dev \
    zlib-static \
    tar \
    git \
    linux-headers

# Build cramfs tools from source
RUN git clone https://github.com/npitre/cramfs-tools.git /tmp/cramfs-tools && \
    cd /tmp/cramfs-tools && \
    make && \
    cp mkcramfs /usr/local/bin/ && \
    rm -rf /tmp/cramfs-tools

COPY * /build/
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]
