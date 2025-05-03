ARG ARCH=x86_64
FROM qemount-builder-native:x86_64

# Add files
RUN mkdir -p /build
ADD root /build/root
WORKDIR /build/root

RUN fint . | cpio -o --format=newc > ../initramfs.cpio
RUN gzip -9 ../initramfs.cpio
