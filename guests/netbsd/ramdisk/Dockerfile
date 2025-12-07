ARG ARCH
FROM localhost/qemount-common-compiler-netbsd-10.0-${ARCH}
ARG ARCH

WORKDIR /build

# Copy build script and root overlay
COPY --chmod=755 build.sh /tmp/build-ramdisk.sh
COPY --chmod=755 assemble.sh /usr/local/bin/assemble.sh
COPY root /build/root

ENTRYPOINT ["/usr/local/bin/assemble.sh"]
