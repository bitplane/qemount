ARG ARCH=x86_64
FROM qemount-common-compiler-${ARCH}
ARG ARCH=x86_64

# Add files
RUN mkdir -p /build
ADD root /build/root
WORKDIR /build/root

RUN find . | cpio -o --format=newc > ../initramfs.cpio
RUN gzip -9 ../initramfs.cpio

# Copy the file to the output directory
RUN mkdir -p /outputs/guests/linux-6.11-${ARCH} && \
    cp /build/initramfs.cpio.gz /outputs/guests/linux-6.11-${ARCH}/initramfs.cpio.gz
