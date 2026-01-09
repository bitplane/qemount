ARG ARCH
FROM localhost/qemount-common-compiler-linux-6-${ARCH}
ARG ARCH

RUN apk add --no-cache e2fsprogs

# Copy the init scripts and build script
COPY root /build/root
COPY --chmod=755 build.sh /usr/local/bin/build.sh

WORKDIR /build

ENTRYPOINT ["/usr/local/bin/build.sh"]
