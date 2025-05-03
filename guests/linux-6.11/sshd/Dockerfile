ARG ARCH=x86_64
FROM qemount-builder-native:x86_64

# Download and extract
RUN mkdir -p /build
WORKDIR /build
RUN wget https://matt.ucc.asn.au/dropbear/releases/dropbear-2025.87.tar.bz2
RUN tar -xf dropbear-2025.87.tar.bz2

# Configure
WORKDIR /build/dropbear-2025.87
RUN ./configure --disable-zlib

# Build
RUN make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" MULTI=1 -j"$(nproc)"
