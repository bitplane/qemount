ARG ARCH=x86_64

FROM qemount-builder-base:$(ARCH)

RUN mkdir -p /build
WORKDIR /build

# Download + Extract
RUN wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.11.tar.xz
RUN tar -xf linux-6.11.tar.xz

# Merge config
WORKDIR /build/linux-6.11
ADD *.config /build/linux-6.11
RUN make defconfig
RUN ./scripts/kconfig/merge_config.sh .config kernel.x86_64.config
RUN ./scripts/kconfig/merge_config.sh .config filesystems.config
RUN make olddefconfig

# Build kernel
RUN make -j"$(nproc)"
