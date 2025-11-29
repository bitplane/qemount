ARG ARCH
FROM localhost/qemount-common-compiler-linux-6-${ARCH}
ARG ARCH

# Copy the init scripts and build script
COPY root /build/root
COPY --chmod=755 build-initramfs.sh /usr/local/bin/build-initramfs.sh

WORKDIR /build

ENTRYPOINT ["/usr/local/bin/build-initramfs.sh"]
