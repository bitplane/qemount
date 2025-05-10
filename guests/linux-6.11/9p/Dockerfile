FROM qemount-common-compiler-${ARCH}
ARG ARCH

WORKDIR /build

# Copy all source files including new ones
COPY *.h *.c /build/

# Compile all files
RUN gcc -Wall -Wextra -static -c *.c

# Link all object files together
RUN gcc -static -o simple9p *.o

# Verify it's statically linked
RUN file simple9p | grep -q "statically linked"

# Test basic functionality
RUN ./simple9p -h || true

# Create output directory
RUN mkdir -p /outputs/guests/linux-6.11/rootfs/${ARCH}/bin

# Copy the binary with stripping
RUN cp -v simple9p /outputs/guests/linux-6.11/rootfs/${ARCH}/bin/simple9p && \
    strip /outputs/guests/linux-6.11/rootfs/${ARCH}/bin/simple9p
