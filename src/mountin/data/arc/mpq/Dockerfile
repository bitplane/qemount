FROM builder/disk/debian
RUN apt-get update && \
    apt-get install -y --no-install-recommends cmake g++ zlib1g-dev libbz2-dev && \
    rm -rf /var/lib/apt/lists/*

# Build StormLib
RUN tar -xzf /host/build/sources/stormlib-9.31.tar.gz -C /tmp && \
    cd /tmp/StormLib-* && \
    cmake -B build -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_SHARED_LIBS=OFF . && \
    cmake --build build -j$(nproc) && \
    cmake --install build && \
    rm -rf /tmp/StormLib-*

# Build mkmpq
COPY mkmpq.c /build/mkmpq.c
RUN gcc -O2 -o /usr/local/bin/mkmpq /build/mkmpq.c \
    -I/usr/local/include -L/usr/local/lib -lstorm -lstdc++ -lz -lbz2

COPY --chmod=755 build.sh /build/build.sh
