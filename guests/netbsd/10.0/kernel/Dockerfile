ARG ARCH
FROM localhost/qemount-common-compiler-netbsd-10.0-${ARCH}
ARG ARCH

WORKDIR /usr/src

# Copy kernel config to arch-specific conf directory
COPY QEMOUNT /tmp/QEMOUNT
RUN NBKERNARCH=$(cat /tmp/nbkernarch) && \
    cp /tmp/QEMOUNT /usr/src/sys/arch/$NBKERNARCH/conf/QEMOUNT

# Build the kernel
RUN NBARCH=$(cat /tmp/nbarch) && \
    ./build.sh -O /usr/obj -T /usr/tools -U -u -j$(nproc) -m $NBARCH kernel=QEMOUNT

# Copy unstripped kernel to outputs (needed for mdsetimage to find symbols)
RUN mkdir -p /outputs/guests/netbsd/10.0/${ARCH}
RUN NBKERNARCH=$(cat /tmp/nbkernarch) && \
    cp /usr/obj/sys/arch/$NBKERNARCH/compile/QEMOUNT/netbsd.gdb \
       /outputs/guests/netbsd/10.0/${ARCH}/netbsd.gdb
