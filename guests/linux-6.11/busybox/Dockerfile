ARG ARCH=x86_64
FROM qemount-builder-native:x86_64
# Download and extract
RUN mkdir -p /build
WORKDIR /build
RUN wget https://busybox.net/downloads/busybox-1.36.1.tar.bz2
RUN tar -xf busybox-1.36.1.tar.bz2
# Merge config
WORKDIR /build/busybox-1.36.1
ADD merge_config.py /build
ADD *.config        /build
ADD ensure_link.sh  /build
RUN make defconfig
RUN ../ensure_link.sh ../busybox.$(ARCH).config busybox.config
RUN python3 ../merge_config.py .config ../busybox.$(ARCH).config .config
RUN yes "" | make oldconfig || true
# Build
RUN make -j"$(nproc)"

