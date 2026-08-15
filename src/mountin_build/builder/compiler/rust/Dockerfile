FROM rust:1.92-slim

# Build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip bash \
    && rm -rf /var/lib/apt/lists/*

# Install zig via pip (cross-compiler toolchain)
RUN pip install --break-system-packages ziglang

# Install cargo-zigbuild
RUN cargo install cargo-zigbuild

# Add all cross-compilation targets
RUN rustup target add \
    x86_64-unknown-linux-musl \
    aarch64-unknown-linux-musl \
    x86_64-unknown-linux-gnu \
    aarch64-unknown-linux-gnu \
    x86_64-pc-windows-gnu \
    x86_64-apple-darwin \
    aarch64-apple-darwin \
    wasm32-wasip1

WORKDIR /build
