ARG ARCH
FROM localhost/qemount-common-compiler-linux-6-${ARCH}
ARG ARCH

# Copy the run script to outputs
RUN mkdir -p /outputs/common/run/qemu-linux
COPY run.sh /outputs/common/run/qemu-linux/run-linux.sh
RUN chmod +x /outputs/common/run/qemu-linux/run-linux.sh
