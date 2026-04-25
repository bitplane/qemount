#!/bin/bash
set -ex

QEMU_TARGETS="x86_64-softmmu,aarch64-softmmu,m68k-softmmu"
JOBS=${JOBS:-$(nproc)}

# Host platforms to build for
PLATFORMS=(
    "x86_64-linux-musl"
    "x86_64-windows-gnu"
    "x86_64-macos"
)

platforms_from_targets() {
    local platforms=()
    local target platform seen

    for target in "$@"; do
        case "$target" in
            bin/qemu-system/*/qemu-system-*)
                platform=${target#bin/qemu-system/}
                platform=${platform%%/*}
                seen=0
                for existing in "${platforms[@]}"; do
                    [ "$existing" = "$platform" ] && seen=1
                done
                [ "$seen" = "0" ] && platforms+=("$platform")
                ;;
        esac
    done

    printf "%s\n" "${platforms[@]}"
}

if [ -n "${QEMU_PLATFORMS:-}" ]; then
    read -r -a PLATFORMS <<< "$QEMU_PLATFORMS"
elif [ "$#" -gt 0 ]; then
    mapfile -t REQUESTED_PLATFORMS < <(platforms_from_targets "$@")
    if [ "${#REQUESTED_PLATFORMS[@]}" -gt 0 ]; then
        PLATFORMS=("${REQUESTED_PLATFORMS[@]}")
    fi
fi

# Map zig target triple to GNU autotools host triple
autotools_host() {
    case "$1" in
        *-windows-gnu) echo "x86_64-w64-mingw32" ;;
        *-macos)       echo "x86_64-apple-darwin" ;;
        *)             echo "$1" ;;
    esac
}

platform_system() {
    case "$1" in
        *-windows-gnu) echo "windows" ;;
        *-macos|*-darwin) echo "darwin" ;;
        *) echo "linux" ;;
    esac
}

platform_c_args() {
    case "$1" in
        *-windows-gnu)
            echo "-D_WIN32_WINNT=0x0602 -DWINVER=0x0602" ;;
        *)
            echo "" ;;
    esac
}

platform_ld_args() {
    case "$1" in
        *-windows-gnu)
            echo "-lws2_32 -liphlpapi -lole32 -loleaut32 -luuid -lwinmm -lversion -lsetupapi -luserenv -lshlwapi -lbcrypt" ;;
        *)
            echo "" ;;
    esac
}

qemu_ld_args() {
    case "$1" in
        *-windows-gnu)
            echo "$(platform_ld_args "$1")" ;;
        *)
            platform_ld_args "$1" ;;
    esac
}

platform_exe_ext() {
    case "$1" in
        *-windows-gnu) echo ".exe" ;;
        *) echo "" ;;
    esac
}

platform_needs_exe_wrapper() {
    case "$1" in
        *-windows-gnu|*-macos|*-darwin) echo "true" ;;
        *) echo "false" ;;
    esac
}

meson_array() {
    local values=$1
    local sep=""

    printf "["
    for value in $values; do
        printf "%s'%s'" "$sep" "$value"
        sep=", "
    done
    printf "]"
}

ensure_macos_sdk() {
    local TARGET=$1
    case "$TARGET" in *-macos|*-darwin) ;; *) return 0 ;; esac
    if [ ! -d /opt/macos-sdk/MacOSX11.3.sdk ]; then
        echo "--- Extracting macOS SDK ---"
        mkdir -p /opt/macos-sdk
        tar xf /host/build/sources/MacOSX11.3.sdk.tar.xz -C /opt/macos-sdk
    fi
    # Synthesise pkg-config files for SDK-provided libraries that QEMU
    # discovers via dependency() rather than cc.find_library(). zlib is
    # the prominent case — meson tries pkg-config first.
    local PREFIX=/opt/$TARGET
    local SDK=/opt/macos-sdk/MacOSX11.3.sdk
    mkdir -p $PREFIX/lib/pkgconfig
    cat > $PREFIX/lib/pkgconfig/zlib.pc << EOF
prefix=$SDK/usr
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: zlib
Description: zlib (from macOS SDK)
Version: 1.2.11
Libs: -L\${libdir} -lz
Cflags: -I\${includedir}
EOF
}

ensure_windows_import_libs() {
    local TARGET=$1
    local PREFIX=/opt/$TARGET
    local ZIG
    local lib
    local ZIG_LIB
    local DEF_DIR

    [[ $TARGET == *"windows-gnu"* ]] || return 0

    ZIG=$(command -v zig 2>/dev/null || command -v python-zig 2>/dev/null) || {
        echo "error: zig not found; cannot create Windows import libraries" >&2
        exit 1
    }

    mkdir -p $PREFIX/lib

    # zig 0.15+ emits ZON (.lib_dir = "..."); older versions emit JSON
    # ("lib_dir": "..."). Match both.
    ZIG_LIB=$($ZIG env 2>/dev/null | sed -n \
        -e 's/.*\.lib_dir[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' \
        -e 's/.*"lib_dir"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
        | head -1)
    # MinGW-w64 splits .def files: lib-common/ holds shared ones (mostly
    # as .def.in templates needing C preprocessing for arch macros), and
    # lib64/ (or lib32/) hold ready-to-use arch-specific .def files.
    # Search lib64 first so it wins on conflict.
    local MINGW_DIR=$ZIG_LIB/libc/mingw
    DEF_DIRS="$MINGW_DIR/lib64 $MINGW_DIR/lib-common"
    local DEF_INCLUDE=$MINGW_DIR/def-include

    if [ -z "$ZIG_LIB" ] || [ ! -d "$MINGW_DIR" ]; then
        echo "error: zig mingw dir not found under '$ZIG_LIB' (ZIG_LIB='$ZIG_LIB')" >&2
        echo "       \$ZIG env output:" >&2
        $ZIG env >&2 || true
        exit 1
    fi

    make_import_lib() {
        local lib=$1
        local dll=${2:-$lib.dll}
        local out=$PREFIX/lib/lib$lib.a
        local d def

        [ -f "$out" ] && return 0

        for d in $DEF_DIRS; do
            # Plain .def: feed straight to dlltool.
            def=$d/$lib.def
            if [ -f "$def" ]; then
                $ZIG dlltool \
                    -m i386:x86-64 \
                    -D "$dll" \
                    -d "$def" \
                    -l "$out"
                return 0
            fi
            # .def.in template: preprocess with zig cc to expand the
            # F_X86_ANY/F_X64/etc. macros for our target arch, then
            # dlltool the result.
            def=$d/$lib.def.in
            if [ -f "$def" ]; then
                local processed=/tmp/$lib.def
                $ZIG cc -target $TARGET -E -P -xc \
                    -I "$DEF_INCLUDE" \
                    -o "$processed" \
                    "$def"
                $ZIG dlltool \
                    -m i386:x86-64 \
                    -D "$dll" \
                    -d "$processed" \
                    -l "$out"
                return 0
            fi
        done

        return 1
    }

    for lib in ws2_32 winmm iphlpapi ole32 oleaut32 uuid version setupapi userenv shlwapi bcrypt; do
        make_import_lib "$lib" || echo "skip: no def for $lib in $DEF_DIR" >&2
    done

    make_import_lib pathcch || make_pathcch_import_lib "$ZIG" "$PREFIX"
    make_import_lib synchronization || make_synchronization_import_lib "$ZIG" "$PREFIX"
}

make_pathcch_import_lib() {
    local ZIG=$1
    local PREFIX=$2

    cat > /work/pathcch.def <<'EOF'
LIBRARY pathcch.dll
EXPORTS
PathAllocCanonicalize
PathAllocCombine
PathCchAddBackslash
PathCchAddBackslashEx
PathCchAddExtension
PathCchAppend
PathCchAppendEx
PathCchCanonicalize
PathCchCanonicalizeEx
PathCchCombine
PathCchCombineEx
PathCchFindExtension
PathCchIsRoot
PathCchRemoveBackslash
PathCchRemoveBackslashEx
PathCchRemoveExtension
PathCchRemoveFileSpec
PathCchRenameExtension
PathCchSkipRoot
PathCchStripPrefix
PathCchStripToRoot
PathIsUNCEx
EOF
    $ZIG dlltool \
        -m i386:x86-64 \
        -D pathcch.dll \
        -d /work/pathcch.def \
        -l $PREFIX/lib/libpathcch.a
}

make_synchronization_import_lib() {
    local ZIG=$1
    local PREFIX=$2

    cat > /work/synchronization.def <<'EOF'
LIBRARY synchronization.dll
EXPORTS
WaitOnAddress
WakeByAddressAll
WakeByAddressSingle
EOF
    $ZIG dlltool \
        -m i386:x86-64 \
        -D synchronization.dll \
        -d /work/synchronization.def \
        -l $PREFIX/lib/libsynchronization.a
}

build_deps_for_target() {
    local TARGET=$1
    local PREFIX=/opt/$TARGET
    local HOST=$(autotools_host $TARGET)
    local WRAPDIR=/opt/zig-wrappers/$TARGET
    local C_ARGS="$(platform_c_args $TARGET)"
    local LD_ARGS="$(platform_ld_args $TARGET)"

    mkdir -p $PREFIX
    ensure_macos_sdk $TARGET
    ensure_windows_import_libs $TARGET

    echo "=== Building deps for $TARGET ==="

    # Extract sources from build dir
    local SRCDIR=/work/sources
    mkdir -p $SRCDIR
    cd $SRCDIR
    [ -d libffi-3.4.6 ]   || tar xf /host/build/sources/libffi-3.4.6.tar.gz
    [ -d libiconv-1.17 ]  || tar xf /host/build/sources/libiconv-1.17.tar.gz
    [ -d pixman-0.44.2 ]  || tar xf /host/build/sources/pixman-0.44.2.tar.gz
    [ -d glib-2.82.4 ]    || tar xf /host/build/sources/glib-2.82.4.tar.xz

    # GLib's cross build first determines size_t by size, then refines that
    # with GCC/Clang warning-clean pointer compatibility probes. On Win64
    # MinGW, size_t is 8 bytes and long is 4 bytes, so the size facts are
    # enough. The extra probe can fail under Zig/Clang's MinGW typedef spelling
    # and report the misleading "Could not determine size of size_t".
    if [[ $TARGET == *"windows-gnu"* ]]; then
        cd $SRCDIR/glib-2.82.4
        if ! grep -q "host_system != 'windows' and (cc.get_id() == 'gcc' or cc.get_id() == 'clang')" meson.build; then
            perl -0pi -e "s/if cc\\.get_id\\(\\) == 'gcc' or cc\\.get_id\\(\\) == 'clang'\\n  foreach type_name, size_compatibility : g_sizet_compatibility/if host_system != 'windows' and (cc.get_id() == 'gcc' or cc.get_id() == 'clang')\\n  foreach type_name, size_compatibility : g_sizet_compatibility/" meson.build
        fi
        grep -q "host_system != 'windows' and (cc.get_id() == 'gcc' or cc.get_id() == 'clang')" meson.build
    fi

    # Use zig wrapper scripts for the entire toolchain
    export PATH="$WRAPDIR:$PATH"
    export CC=$WRAPDIR/cc
    export CXX=$WRAPDIR/c++
    export AR=$WRAPDIR/ar
    export RANLIB=$WRAPDIR/ranlib
    export LD=$WRAPDIR/ld
    export STRIP=$WRAPDIR/strip
    export OBJCOPY=$WRAPDIR/objcopy
    export CFLAGS="-I$PREFIX/include $C_ARGS"
    export CPPFLAGS="-I$PREFIX/include $C_ARGS"
    export LDFLAGS="-L$PREFIX/lib $LD_ARGS"
    export PKG_CONFIG_ALL_STATIC=1

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
        # libiconv 1.17's iconv.c uses errno/E2BIG/EILSEQ but doesn't
        # include <errno.h>, relying on transitive includes that don't
        # exist via stdlib.h on macOS.
        if [[ $TARGET == *"macos"* || $TARGET == *"darwin"* ]]; then
            grep -q "^#include <errno.h>" lib/iconv.c || \
                sed -i '/^#include <iconv.h>/a #include <errno.h>' lib/iconv.c
        fi
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
    export PKG_CONFIG_LIBDIR=$PREFIX/lib/pkgconfig
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
    local C_ARGS="$(platform_c_args $TARGET)"
    local LD_ARGS="$(qemu_ld_args $TARGET)"

    mkdir -p $OUTDIR

    echo "=== Building QEMU for $TARGET ==="

    cd /work
    tar xf /host/build/sources/qemu-10.2.0.tar.xz
    cd qemu-10.2.0

    # SDK 11.3 only has IOMasterPort (renamed to IOMainPort in macOS 12).
    # On real macOS 12+, IOMasterPort is still an alias, so binaries
    # built against the older symbol run fine on newer systems.
    if [[ $TARGET == *"macos"* || $TARGET == *"darwin"* ]]; then
        sed -i 's/\bIOMainPort\b/IOMasterPort/g' block/file-posix.c
    fi

    # Configure with cross-compile settings.
    # Unset CC/CXX/AR/etc. inherited from the deps build so meson
    # detects the native (build-machine) compiler from PATH for tools
    # like target/hexagon/gen_semantics.c that compile-and-run during
    # the build. The host-machine (target) compiler is set via --cc/--cxx
    # below.
    unset CC CXX AR RANLIB LD STRIP OBJCOPY CFLAGS CPPFLAGS LDFLAGS
    export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
    export PKG_CONFIG_LIBDIR=$PREFIX/lib/pkgconfig
    export PKG_CONFIG_ALL_STATIC=1

    # macOS forbids fully-static binaries — Apple only ships dynamic
    # libSystem stubs. Build dynamic on darwin, static elsewhere.
    local STATIC_FLAG="--static"
    case "$TARGET" in *-macos|*-darwin) STATIC_FLAG="" ;; esac

    ./configure \
        --cross-prefix="" \
        --cc="$WRAPDIR/cc" \
        --cxx="$WRAPDIR/c++" \
        --host-cc=gcc \
        --target-list=$QEMU_TARGETS \
        --prefix=/usr \
        $STATIC_FLAG \
        --without-default-features \
        --disable-werror \
        --disable-install-blobs \
        --audio-drv-list= \
        --extra-cflags="-I$PREFIX/include -UNDEBUG $C_ARGS" \
        --extra-ldflags="-L$PREFIX/lib $LD_ARGS"

    make -j$JOBS

    # Copy outputs. On macOS, QEMU's meson build produces *-unsigned
    # binaries expecting a post-build codesign step. We don't sign in
    # the build container — users can ad-hoc sign with `codesign -s -`
    # on their mac, or run via `xattr -d com.apple.quarantine`.
    local EXT="$(platform_exe_ext $TARGET)"
    local SUFFIX=""
    case "$TARGET" in *-macos|*-darwin) SUFFIX="-unsigned" ;; esac

    cp build/qemu-system-x86_64$SUFFIX$EXT $OUTDIR/qemu-system-x86_64$EXT
    cp build/qemu-system-aarch64$SUFFIX$EXT $OUTDIR/qemu-system-aarch64$EXT
    cp build/qemu-system-m68k$SUFFIX$EXT $OUTDIR/qemu-system-m68k$EXT

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
    local SYSTEM="$(platform_system $TARGET)"
    local NEEDS_EXE_WRAPPER="$(platform_needs_exe_wrapper $TARGET)"
    local C_ARGS="-I$PREFIX/include $(platform_c_args $TARGET)"
    local LD_ARGS="-L$PREFIX/lib $(platform_ld_args $TARGET)"
    local MESON_C_ARGS="$(meson_array "$C_ARGS")"
    local MESON_LD_ARGS="$(meson_array "$LD_ARGS")"

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
c_args = $MESON_C_ARGS
c_link_args = $MESON_LD_ARGS
cpp_args = $MESON_C_ARGS
cpp_link_args = $MESON_LD_ARGS

[properties]
needs_exe_wrapper = $NEEDS_EXE_WRAPPER

[host_machine]
system = '$SYSTEM'
cpu_family = 'x86_64'
cpu = 'x86_64'
endian = 'little'
EOF
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
