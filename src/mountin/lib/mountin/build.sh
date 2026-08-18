#!/bin/bash
set -e

OUT=/host/build/lib
TARGET=${CARGO_TARGET_DIR:-target}

# Target filtering: if args passed, only build matching targets
TARGETS="$*"
want() { [ -z "$TARGETS" ] || echo "$TARGETS" | grep -q "$1"; }

# Linux musl (fully static, portable - no .so, musl doesn't support cdylib)
for arch in x86_64 aarch64; do
    if want "lib/${arch}-linux-musl/"; then
        # Cargo warns while dropping the manifest's cdylib output for musl.
        # Quiet mode suppresses that expected Cargo message; compiler diagnostics
        # are still emitted.
        cargo zigbuild --quiet --release --target ${arch}-unknown-linux-musl -j $MOUNTIN_BUILD_JOBS
        mkdir -p ${OUT}/${arch}-linux-musl
        cp ${TARGET}/${arch}-unknown-linux-musl/release/libmountin.a ${OUT}/${arch}-linux-musl/
    fi
done

# Linux gnu (glibc 2.17 compat)
for arch in x86_64 aarch64; do
    if want "lib/${arch}-linux-gnu/"; then
        cargo zigbuild --release --target ${arch}-unknown-linux-gnu.2.17 -j $MOUNTIN_BUILD_JOBS
        mkdir -p ${OUT}/${arch}-linux-gnu
        cp ${TARGET}/${arch}-unknown-linux-gnu/release/libmountin.a ${OUT}/${arch}-linux-gnu/
        cp ${TARGET}/${arch}-unknown-linux-gnu/release/libmountin.so ${OUT}/${arch}-linux-gnu/
    fi
done

# Windows (x86_64 only - aarch64-pc-windows-gnu not a supported Rust target)
if want "lib/x86_64-windows-gnu/"; then
    cargo zigbuild --release --target x86_64-pc-windows-gnu -j $MOUNTIN_BUILD_JOBS
    mkdir -p ${OUT}/x86_64-windows-gnu
    cp ${TARGET}/x86_64-pc-windows-gnu/release/mountin.dll ${OUT}/x86_64-windows-gnu/
    cp ${TARGET}/x86_64-pc-windows-gnu/release/libmountin.a ${OUT}/x86_64-windows-gnu/mountin.lib
fi

# macOS
for arch in x86_64 aarch64; do
    if want "lib/${arch}-darwin/"; then
        cargo zigbuild --release --target ${arch}-apple-darwin -j $MOUNTIN_BUILD_JOBS
        mkdir -p ${OUT}/${arch}-darwin
        cp ${TARGET}/${arch}-apple-darwin/release/libmountin.a ${OUT}/${arch}-darwin/
        cp ${TARGET}/${arch}-apple-darwin/release/libmountin.dylib ${OUT}/${arch}-darwin/
    fi
done

# WASM
if want "lib/wasm32-wasi/"; then
    cargo zigbuild --release --target wasm32-wasip1 -j $MOUNTIN_BUILD_JOBS
    mkdir -p ${OUT}/wasm32-wasi
    cp ${TARGET}/wasm32-wasip1/release/mountin.wasm ${OUT}/wasm32-wasi/
fi

# C header (always needed if any lib is built)
if want "lib/include/"; then
    mkdir -p ${OUT}/include
    cp /build/include/mountin.h ${OUT}/include/
fi

echo "Build complete"
