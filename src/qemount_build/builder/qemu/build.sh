#!/bin/bash
set -e

QEMU_TARGETS="x86_64-softmmu,aarch64-softmmu,m68k-softmmu"
JOBS=${JOBS:-$(nproc)}

# Host platforms to build for
PLATFORMS=(
    "x86_64-linux-musl"
    # "x86_64-windows-gnu"  # needs MinGW-w64 SDK (pathcch, synchronization)
    # "x86_64-macos"        # zig missing macOS SDK headers (nameser, xattr)
)

# Map zig target triple to GNU autotools host triple
autotools_host() {
    case "$1" in
        *-windows-gnu) echo "x86_64-w64-mingw32" ;;
        *-macos)       echo "x86_64-apple-darwin" ;;
        *)             echo "$1" ;;
    esac
}

build_deps_for_target() {
    local TARGET=$1
    local PREFIX=/opt/$TARGET
    local HOST=$(autotools_host $TARGET)
    local WRAPDIR=/opt/zig-wrappers/$TARGET

    mkdir -p $PREFIX

    echo "=== Building deps for $TARGET ==="

    # Extract sources from build dir
    local SRCDIR=/work/sources
    mkdir -p $SRCDIR
    cd $SRCDIR
    [ -d libffi-3.4.6 ]   || tar xf /host/build/sources/libffi-3.4.6.tar.gz
    [ -d libiconv-1.17 ]  || tar xf /host/build/sources/libiconv-1.17.tar.gz
    [ -d pixman-0.44.2 ]  || tar xf /host/build/sources/pixman-0.44.2.tar.gz
    [ -d glib-2.82.4 ]    || tar xf /host/build/sources/glib-2.82.4.tar.xz

    # Use zig wrapper scripts for the entire toolchain
    export PATH="$WRAPDIR:$PATH"
    export CC=$WRAPDIR/cc
    export CXX=$WRAPDIR/c++
    export AR=$WRAPDIR/ar
    export RANLIB=$WRAPDIR/ranlib
    export LD=$WRAPDIR/ld
    export STRIP=$WRAPDIR/strip
    export OBJCOPY=$WRAPDIR/objcopy

    # Build libffi
    echo "--- Building libffi for $TARGET ---"
    cd $SRCDIR/libffi-3.4.6
    rm -rf build-$TARGET && mkdir build-$TARGET && cd build-$TARGET
    ../configure \
        --prefix=$PREFIX \
        --host=$HOST \
        --disable-shared \
        --enable-static \
        --disable-docs
    make -j$JOBS
    make install

    # Build libiconv (needed for non-linux targets; musl has iconv built-in)
    if [[ $TARGET != *"linux"* ]]; then
        echo "--- Building libiconv for $TARGET ---"
        cd $SRCDIR/libiconv-1.17
        rm -rf build-$TARGET && mkdir build-$TARGET && cd build-$TARGET
        ../configure \
            --prefix=$PREFIX \
            --host=$HOST \
            --disable-shared \
            --enable-static
        make -j$JOBS
        make install
    fi

    # Build pixman
    echo "--- Building pixman for $TARGET ---"
    export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
    cd $SRCDIR/pixman-0.44.2
    rm -rf build-$TARGET && mkdir build-$TARGET && cd build-$TARGET
    meson setup \
        --prefix=$PREFIX \
        --cross-file=/work/zig-$TARGET.cross \
        --default-library=static \
        -Dgtk=disabled \
        -Dlibpng=disabled \
        -Dtests=disabled \
        ..
    ninja -j$JOBS
    ninja install

    # Build glib (minimal, no gio)
    echo "--- Building glib for $TARGET ---"
    export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
    export PKG_CONFIG_LIBDIR=$PREFIX/lib/pkgconfig
    cd $SRCDIR/glib-2.82.4
    rm -rf build-$TARGET && mkdir build-$TARGET && cd build-$TARGET
    meson setup \
        --prefix=$PREFIX \
        --cross-file=/work/zig-$TARGET.cross \
        --default-library=static \
        -Dtests=false \
        -Dintrospection=disabled \
        -Dglib_debug=disabled \
        -Dxattr=false \
        -Dgio_module_dir=/nonexistent \
        ..
    ninja -j$JOBS
    ninja install

    echo "=== Deps built for $TARGET ==="
}

build_qemu_for_target() {
    local TARGET=$1
    local PREFIX=/opt/$TARGET
    local WRAPDIR=/opt/zig-wrappers/$TARGET
    local OUTDIR=/host/build/bin/qemu-system/$TARGET

    mkdir -p $OUTDIR

    echo "=== Building QEMU for $TARGET ==="

    cd /work
    tar xf /host/build/sources/qemu-10.2.0.tar.xz
    cd qemu-10.2.0

    # Configure with cross-compile settings
    export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
    export PKG_CONFIG_LIBDIR=$PREFIX/lib/pkgconfig

    ./configure \
        --cross-prefix="" \
        --cc="$WRAPDIR/cc" \
        --cxx="$WRAPDIR/c++" \
        --target-list=$QEMU_TARGETS \
        --prefix=/usr \
        --static \
        --without-default-features \
        --disable-werror \
        --disable-install-blobs \
        --audio-drv-list= \
        --extra-cflags="-I$PREFIX/include -UNDEBUG" \
        --extra-ldflags="-L$PREFIX/lib"

    make -j$JOBS

    # Copy outputs
    local EXT=""
    if [[ $TARGET == *"windows"* ]]; then
        EXT=".exe"
    fi

    cp build/qemu-system-x86_64$EXT $OUTDIR/
    cp build/qemu-system-aarch64$EXT $OUTDIR/
    cp build/qemu-system-m68k$EXT $OUTDIR/

    # Strip binaries
    # zig doesn't have strip for all targets, so skip if not available
    strip $OUTDIR/qemu-system-* 2>/dev/null || true

    echo "=== QEMU built for $TARGET ==="
    ls -la $OUTDIR/

    # Clean up for next target
    cd /work
    rm -rf qemu-10.2.0
}

# Generate meson cross files for each target
generate_cross_file() {
    local TARGET=$1
    local WRAPDIR=/opt/zig-wrappers/$TARGET

    local PREFIX=/opt/$TARGET

    cat > /work/zig-$TARGET.cross << EOF
[binaries]
c = '$WRAPDIR/cc'
cpp = '$WRAPDIR/c++'
objc = '$WRAPDIR/cc'
ar = '$WRAPDIR/ar'
ranlib = '$WRAPDIR/ranlib'
strip = '$WRAPDIR/strip'
windres = '$WRAPDIR/windres'
pkgconfig = 'pkg-config'

[built-in options]
c_args = ['-I$PREFIX/include']
c_link_args = ['-L$PREFIX/lib']
cpp_args = ['-I$PREFIX/include']
cpp_link_args = ['-L$PREFIX/lib']

[host_machine]
system = 'linux'
cpu_family = 'x86_64'
cpu = 'x86_64'
endian = 'little'
EOF

    # Adjust system for non-linux targets
    if [[ $TARGET == *"windows"* ]]; then
        sed -i "s/system = 'linux'/system = 'windows'/" /work/zig-$TARGET.cross
    elif [[ $TARGET == *"macos"* ]] || [[ $TARGET == *"darwin"* ]]; then
        sed -i "s/system = 'linux'/system = 'darwin'/" /work/zig-$TARGET.cross
    fi
}

# Main build loop
for PLATFORM in "${PLATFORMS[@]}"; do
    echo ""
    echo "######################################"
    echo "# Building for: $PLATFORM"
    echo "######################################"
    echo ""

    # Create zig wrapper scripts first
    WRAPDIR=/opt/zig-wrappers/$PLATFORM
    /zig-wrapper.sh $PLATFORM $WRAPDIR

    generate_cross_file $PLATFORM
    build_deps_for_target $PLATFORM
    build_qemu_for_target $PLATFORM
done

echo ""
echo "=== All builds complete ==="
ls -laR /host/build/bin/qemu-system/
