ARG ARCH
FROM localhost/qemount-common-compiler-netbsd-10.0-${ARCH}
ARG ARCH

WORKDIR /build

# Copy build script and root overlay
COPY --chmod=755 build.sh /tmp/build-ramdisk.sh
COPY root /build/root

# Build ramdisk directory structure with rescue binaries
RUN NBARCH=$(cat /tmp/nbarch) && \
    /tmp/build-ramdisk.sh /usr/obj/destdir.$NBARCH /ramdisk

# Copy init scripts and etc files from root overlay
RUN cp -v /build/root/sbin/init /ramdisk/sbin/init && \
    chmod 755 /ramdisk/sbin/init && \
    cp -v /build/root/init.sh /ramdisk/init.sh && \
    chmod 755 /ramdisk/init.sh && \
    cp -v /build/root/init.9p /ramdisk/init.9p && \
    chmod 755 /ramdisk/init.9p && \
    cp -v /build/root/etc/* /ramdisk/etc/

# Create ramdisk filesystem image (12MB for rescue binary)
# Use FFS v1 for compatibility with memory disk boot
RUN /usr/tools/bin/nbmakefs -s 12m -t ffs -o version=1 /ramdisk.fs /ramdisk

# Copy to outputs
RUN mkdir -p /outputs/guests/netbsd/ramdisk/${ARCH}
RUN cp /ramdisk.fs /outputs/guests/netbsd/ramdisk/${ARCH}/ramdisk.fs
