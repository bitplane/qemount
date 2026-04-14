FROM builder/disk/debian

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates curl gcc libc6-dev && \
    rm -rf /var/lib/apt/lists/*

RUN curl -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile minimal && \
    . /root/.cargo/env && \
    cargo install --root /usr/local amiga-lzx-cli --version 0.1.1 && \
    rustup self uninstall -y

COPY --chmod=755 build.sh /build/build.sh
