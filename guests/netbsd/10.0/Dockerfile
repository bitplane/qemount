ARG ARCH
FROM localhost/qemount-common-compiler-netbsd-10.0-${ARCH}
ARG ARCH

WORKDIR /build

# Copy boot config files
COPY boot.cfg /build/boot.cfg
COPY disklabel.proto /build/disklabel.proto

# Copy assembly script
COPY --chmod=755 assemble.sh /usr/local/bin/assemble.sh

ENTRYPOINT ["/usr/local/bin/assemble.sh"]
